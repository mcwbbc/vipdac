require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Job do

  before(:each) do
    @job = create_job
  end

  describe "create" do
    [:name, :searcher, :parameter_file_id, :datafile_id, :spectra_count, :priority].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_job(key => nil).should_not be_valid
      end
    end
  end

  describe "create spectra count" do
    it "should be a number" do
      create_job(:spectra_count => "cheese").should_not be_valid
    end
  end

  describe "incomplete" do
    it "should return jobs that aren't complete" do
      job = mock_model(Job)
      Job.should_receive(:find).with(:all, :conditions => ["status != ?", "Complete"]).and_return([job])
      Job.incomplete.should == [job]
    end
  end

  describe "stuck_packing?" do
    describe "when not stuck" do
      it "should return false if we're not packing" do
        @job.should_receive(:packing?).and_return(false)
        @job.stuck_packing?.should be_false
      end

      it "should be false if it started packing less than 20 minutes ago" do
        @job.should_receive(:packing?).and_return(true)
        @job.should_receive(:started_pack_at).and_return(5.minutes.ago.to_f)
        @job.stuck_packing?.should be_false
      end
    end

    describe "when stuck" do
      it "should be true if we're packing at it's been more than 20 minutes since we started" do
        @job.should_receive(:packing?).and_return(true)
        @job.should_receive(:started_pack_at).and_return(1215.seconds.ago.to_f)
        @job.stuck_packing?.should be_true
      end
    end
  end

  describe "stuck_chunks?" do
    before(:each) do
      @chunk = mock_model(Chunk)
      @complete = mock("complete")
      @incomplete = mock("incomplete")
      @chunks = mock("chunks", :complete => @complete, :incomplete => @incomplete)
      @job.stub!(:chunks).and_return(@chunks)
    end

    it "should be false if no chunks" do
      @incomplete.should_receive(:empty?).and_return(true)
      @job.stuck_chunks?.should be_false
    end

    it "should be false if we've finished all the chunks" do
      @incomplete.should_receive(:empty?).and_return(true)
      @job.stuck_chunks?.should be_false
    end

    it "should be true if it finished more than 20 minutes ago" do
      @incomplete.should_receive(:empty?).and_return(false)
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(@chunk)
      @chunk.should_receive(:finished_at).and_return(1215.seconds.ago.to_f)
      @job.stuck_chunks?.should be_true
    end

    it "should be false if it finished less than 20 minutes ago" do
      @incomplete.should_receive(:empty?).and_return(false)
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(@chunk)
      @chunk.should_receive(:finished_at).and_return(5.minutes.ago.to_f)
      @job.stuck_chunks?.should be_false
    end

    it "should be false if we didn't get a chunk for complete first" do
      @incomplete.should_receive(:empty?).and_return(false)
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(nil)
      @job.stuck_chunks?.should be_false
    end
  end

  describe "resend_stuck_chunks" do
    it "should resend process messages for incomplete chunks" do
      chunk = mock_model(Chunk)
      chunk.should_receive(:send_process_message).and_return(true)
      incomplete = [chunk]
      chunks = mock("chunks", :incomplete => incomplete)
      @job.should_receive(:chunks).and_return(chunks)
      @job.resend_stuck_chunks
    end
  end

  describe "when displaying chunk times" do
    describe "maximum" do
      it "should show the processing time" do
        @job.chunks.should_receive(:maximum).and_return(20)
        @job.maximum_chunk_time.should eql(20.0)
      end

      it "should return zero for an exception" do
        @job.chunks.should_receive(:maximum).and_raise("exception")
        @job.maximum_chunk_time.should eql(0)
      end
    end
    describe "minimum" do
      it "should show the processing time" do
        @job.chunks.should_receive(:minimum).and_return(10)
        @job.minimum_chunk_time.should eql(10.0)
      end
      it "should return zero for a negative number" do
        @job.chunks.should_receive(:minimum).and_return(-10000)
        @job.minimum_chunk_time.should eql(0)
      end
      it "should return zero for an exception" do
        @job.chunks.should_receive(:minimum).and_raise("exception")
        @job.minimum_chunk_time.should eql(0)
      end
    end
    describe "average" do
      it "should show the processing time" do
        @job.chunks.should_receive(:average).and_return(15)
        @job.average_chunk_time.should eql(15)
      end
      it "should return zero for a negative number" do
        @job.chunks.should_receive(:average).and_return(-10000)
        @job.average_chunk_time.should eql(0)
      end
      it "should return zero for an exception" do
        @job.chunks.should_receive(:average).and_raise("exception")
        @job.average_chunk_time.should eql(0)
      end
    end
  end

  describe "processing time" do
    it "should return zero for an exception" do
      @job.chunks.should_receive(:minimum).and_raise("exception")
      @job.processing_time.should eql(0)
    end
    it "should return the processing time" do
      @job.chunks.should_receive(:minimum).and_return(10.0)
      @job.chunks.should_receive(:maximum).and_return(25.0)
      @job.processing_time.should eql(15.0)
    end
  end

  describe "remove_s3_files" do
    it "should remove a file from s3 and return true" do
      @job.should_receive(:hash_key).and_return("hashkey")
      Aws.should_receive(:delete_object).with("hashkey/parameters.conf").and_return(true)
      @job.remove_s3_files
    end
  end

  describe "parameter file name" do
    it "should return the name of the parameter file used by the job" do
      pf = mock("parameter_file")
      pf.should_receive(:name).and_return("Big Name")
      @job.should_receive(:load_parameter_file).and_return(pf)
      @job.parameter_file_name.should == "bigname"
    end
  end

  describe "remove s3 working folder" do
    it "should delete the folder from s3" do
      @job.should_receive(:hash_key).and_return('hash_key')
      Aws.should_receive(:delete_folder).with("hash_key").and_return(true)
      @job.remove_s3_working_folder
    end
  end

  describe "destroy" do
    it "should remove the s3 files" do
      @job.should_receive(:remove_s3_files).and_return(true)
      @job.should_receive(:remove_s3_working_folder).and_return(true)
      @job.destroy
    end
  end

  describe "packing" do
    it "should return true for status == 'Packing'" do
      @job.should_receive(:status).and_return("Packing")
      @job.packing?.should be_true
    end

    it "should return true for status == 'Requested packing'" do
      @job.should_receive(:status).twice.and_return("Requested packing")
      @job.packing?.should be_true
    end

    it "should return false for status != 'Packing' || 'Requested packing'" do
      @job.should_receive(:status).twice.and_return("cheese")
      @job.packing?.should be_false
    end
  end

  describe "pending" do
    it "should return true for status == 'Pending'" do
      @job.should_receive(:status).and_return("Pending")
      @job.pending?.should be_true
    end
    it "should return false for status != 'Pending'" do
      @job.should_receive(:status).and_return("cheese")
      @job.pending?.should be_false
    end
  end

  describe "complete" do
    it "should return true for status == 'Complete'" do
      @job.should_receive(:status).and_return("Complete")
      @job.complete?.should be_true
    end
    it "should return false for status != 'Complete'" do
      @job.should_receive(:status).and_return("cheese")
      @job.complete?.should be_false
    end
  end

  describe "upload manifest" do
    it "should put the manifest file on s3" do
      @job.should_receive(:hash_key).and_return('hash_key')
      @job.should_receive(:output_files).twice.and_return("hello")
      @job.should_receive(:send_verified_data).with("hash_key/manifest.yml", "hello".to_yaml, "6e6d6e9bfe05ac6c395d93627a764f84", {}).and_return(true)
      @job.upload_manifest
    end
  end

  describe "output files" do
    it "should return an array of filenames" do
      @job.should_receive(:hash_key).and_return("hash")
      @job.should_receive(:remote_file_list).with("hash/out").and_return(["file1", "file2"])
      @job.output_files.should == ["file1", "file2"]
    end
  end

  describe "resultfile name" do
    it "should create a name for the result file based on the job attributes" do
      @job.should_receive(:search_database).and_return("database")
      @job.should_receive(:parameter_file_name).and_return("parameterfilename")
      df = mock("datafile")
      df.should_receive(:uploaded_file_name).and_return("thing.mgf")
      @job.should_receive(:datafile).and_return(df)
      @job.resultfile_name.should == "jobname_thing_database_omssa_parameterfilename_200"
    end
  end

  describe "clean string" do
    it "should return a downcased string with no spaces, odd characters" do
      @job.clean_string("Hello There!!").should == "hellothere"
    end
  end

  describe "processed?" do
    before(:each) do
      @chunk = mock_model(Chunk)
      @chunks = mock("chunks")
      @chunk.should_receive(:chunk_count).and_return(2)
      @chunks.should_receive(:first).and_return(@chunk)
      @job.should_receive(:chunks).exactly(3).times.and_return(@chunks)
    end
    
    it "should return false if all chunks aren't complete" do
      @chunks.should_receive(:inject).with(true).and_return(false)
      @chunks.should_receive(:size).and_return(2)
      @job.processed?.should be_false
    end

    it "should return false if don't have all the chunks" do
      @chunks.should_receive(:inject).with(true).and_return(true)
      @chunks.should_receive(:size).and_return(1)
      @job.processed?.should be_false
    end

    it "should return true if all chunks have been completed" do
      @chunks.should_receive(:inject).with(true).and_return(true)
      @chunks.should_receive(:size).and_return(2)
      @job.processed?.should be_true
    end
  end

  describe "load parameter file" do
    describe "for tandem" do
      it "should load the parameter_file" do
        job = create_job(:searcher => "tandem")
        tandem = mock_model(TandemParameterFile)
        TandemParameterFile.should_receive(:find).with(1).and_return(tandem)
        job.load_parameter_file.should == tandem
      end
    end

    describe "for omssa" do
      it "should load the parameter_file" do
        job = create_job(:searcher => "omssa")
        omssa = mock_model(OmssaParameterFile)
        OmssaParameterFile.should_receive(:find).with(1).and_return(omssa)
        job.load_parameter_file.should == omssa
      end
    end
  end

  describe "create parameter textfile" do
    describe "for tandem" do
      it "should write out the file" do
        pf = mock("parameter_file")
        pf.should_receive(:write_file).with(/vipdac\/tmp/).and_return(true)
        job = create_job
        job.create_parameter_textfile(pf).should be_true
      end
    end
  end

  describe "set defaults" do
    before(:each) do
      Digest::SHA1.stub!(:hexdigest).and_return("hex")
      @job.set_defaults
    end

    it "should set the status" do
      @job.status.should eql("Pending")
    end

    it "should set hash_key" do
      @job.hash_key.should eql("hex")
    end

    it "should set created_at" do
      @job.created_at.should_not be_nil
    end
  end

  describe "upload parameter file to s3" do
    it "should put the parameter file on s3" do
      @job.should_receive(:hash_key).and_return("hashkey")
      @job.should_receive(:local_parameter_file).and_return("local_parameter_file")
      @job.should_receive(:send_file).with("hashkey/#{PARAMETER_FILENAME}", "local_parameter_file").and_return(true)
      @job.upload_parameter_file_to_s3.should be_true
    end
  end

  describe "send_background_upload_message" do
    it "should send a background upload head message" do
      @job.should_receive(:id).and_return(12)
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => BACKGROUNDUPLOAD, :job_id => 12}.to_yaml, :priority => 50, :ttr => 1200).and_return(true)
      @job.send_background_upload_message
    end
  end

  describe "send message" do
    before(:each) do
      datafile = mock("datafile", :uploaded_file_name => "uploaded.mgf")
      
      @job.should_receive(:resultfile_name).and_return("resultfile.zip")
      @job.should_receive(:id).and_return(12)
      @job.should_receive(:hash_key).and_return('hash_key')
      @job.should_receive(:spectra_count).and_return(100)
      @job.should_receive(:priority).and_return(1000)
      @job.should_receive(:datafile).and_return(datafile)
      @job.should_receive(:search_database).and_return("search_database")
      Aws.should_receive(:bucket_name).and_return("bucket")
    end

    it "should send a pack node message" do
      MessageQueue.should_receive(:put).with(:name => 'node', :message => {:type => PACK, :bucket_name => "bucket", :job_id => 12, :hash_key => 'hash_key', :datafile => "uploaded.mgf", :resultfile_name => "resultfile.zip", :searcher => "omssa", :search_database => "search_database", :spectra_count => 100, :priority => 1000}.to_yaml, :priority => 50, :ttr => 1200).and_return(true)
      @job.send_message(PACK)
    end

    it "should send an unpack node message" do
      MessageQueue.should_receive(:put).with(:name => 'node', :message => {:type => UNPACK, :bucket_name => "bucket", :job_id => 12, :hash_key => 'hash_key', :datafile => "uploaded.mgf", :resultfile_name => "resultfile.zip", :searcher => "omssa", :search_database => "search_database", :spectra_count => 100, :priority => 1000}.to_yaml, :priority => 50, :ttr => 1200).and_return(true)
      @job.send_message(UNPACK)
    end
  end

  describe "send pack request" do
    it "should send the pack message if the manifest uploaded" do
      Time.stub!(:now).and_return(1.0)
      @job.should_receive(:upload_manifest).and_return(true)
      @job.should_receive(:started_pack_at=).with(1.0).and_return(true)
      @job.should_receive(:status=).with("Requested packing").and_return(true)
      @job.should_receive(:save!).and_return(true)
      @job.should_receive(:send_message).with(PACK).and_return(true)
      @job.send_pack_request
    end
  end

  describe "page" do
    it "should call paginate" do
      Job.should_receive(:paginate).with({:page => 2, :order => 'created_at DESC', :per_page => 20}).and_return(true)
      Job.page(2,20)
    end
  end

  describe "background_s3_upload" do
    it "should run the steps" do
      parameter_file = mock("paramter_file")
      @job.should_receive(:load_parameter_file).ordered.and_return(parameter_file)
      @job.should_receive(:create_parameter_textfile).with(parameter_file).ordered.and_return(true)
      @job.should_receive(:upload_parameter_file_to_s3).ordered.and_return(true)
      @job.should_receive(:send_message).with(UNPACK).ordered.and_return(true)
      @job.background_s3_upload
    end
  end

  describe "search database" do
    it "should return the search database from the parameter file" do
      pf = mock("parameter_file")
      pf.should_receive(:database).and_return("db.fasta")
      @job.should_receive(:load_parameter_file).and_return(pf)
      @job.search_database.should == "db"
    end
  end

  describe "launch" do
    before(:each) do
      @job.should_receive(:send_background_upload_message).and_return(true)
      @job.should_receive(:save).and_return(true)
      Time.stub!(:now).and_return(1.0)
      @job.launch
    end

    it "should set status to launching" do
      @job.status.should eql("Launching")
    end

    it "should set launched at to 1.0" do
      @job.launched_at.should eql(1.0)
    end
  end

  describe "local parameter file" do
    it "should return the local parameter file" do
      @job.local_parameter_file.should match(/parameters.conf$/)
    end
  end

  describe "statistics" do
    it "should return a json string of the statistical data" do
      @job.launched_at = 1.0
      @job.finished_at = 3.0
      @job.started_pack_at = 2.0
      chunk = mock_model(Chunk)
      chunk.should_receive(:stats_hash).and_return({'instance_size' => 'c1.medium'})
      @job.should_receive(:chunks).and_return([chunk])
      @job.statistics.should == {"launched_at"=>1.0, "searcher"=>"omssa", "finished_at"=>3.0, "spectra_count"=>200, "chunks"=>[{"instance_size"=>"c1.medium"}], "started_pack_at"=>2.0}
    end
  end

  protected
    def create_job(options = {})
      record = Job.new({ :name => "jobname", :datafile_id => 10, :searcher => "omssa", :parameter_file_id => 1, :spectra_count => 200, :priority => 1000 }.merge(options))
      record
    end
end
