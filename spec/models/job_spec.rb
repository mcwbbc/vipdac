require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Job do

  before(:each) do
    @job = create_job
  end

  describe "create" do
    [:name, :searcher, :parameter_file_id, :mgf_file_name, :spectra_count, :priority].each do |key|
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

      it "should be false if it started packing less than 10 minutes ago" do
        @job.should_receive(:packing?).and_return(true)
        @job.should_receive(:started_pack_at).and_return(5.minutes.ago.to_f)
        @job.stuck_packing?.should be_false
      end
    end

    describe "when stuck" do
      it "should be true if we're packing at it's been more than 10 minutes since we started" do
        @job.should_receive(:packing?).and_return(true)
        @job.should_receive(:started_pack_at).and_return(11.minutes.ago.to_f)
        @job.stuck_packing?.should be_true
      end
    end
  end

  describe "stuck_chunks?" do
    before(:each) do
      @chunk = mock_model(Chunk)
      @complete = mock("complete")
      @chunks = mock("chunks", :complete => @complete)
      @job.should_receive(:chunks).and_return(@chunks)
    end
    it "should be false if no chunks" do
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(nil)
      @job.stuck_chunks?.should be_false
    end
    it "should be true if it finished more than 10 minutes ago" do
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(@chunk)
      @chunk.should_receive(:finished_at).and_return(11.minutes.ago.to_f)
      @job.stuck_chunks?.should be_true
    end
    it "should be false if it finished less than 10 minutes ago" do
      @complete.should_receive(:first).with(:order => 'finished_at DESC').and_return(@chunk)
      @chunk.should_receive(:finished_at).and_return(5.minutes.ago.to_f)
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
    before(:each) do
      @job.datafile = "hello.zip"
    end
    
    it "should have the proper key" do
      @job.s3_results_key.should eql("completed-jobs/hello-results.zip")
    end
    
    it "should remove a file from s3 and return true" do
      Aws.stub!(:delete_object).and_return(true)
      @job.remove_s3_files
    end
  end

  describe "remove s3 working folder" do
    it "should delete the folder from s3" do
      @job.should_receive(:id).and_return(12)
      Aws.should_receive(:delete_folder).with("12").and_return(true)
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
      @job.should_receive(:id).and_return(12)
      @job.should_receive(:output_files).twice.and_return("hello")
      @job.should_receive(:send_verified_data).with("12/manifest.yml", "hello".to_yaml, "6e6d6e9bfe05ac6c395d93627a764f84", {}).and_return(true)
      @job.upload_manifest
    end
  end

  describe "output files" do
    before(:each) do
      @job.should_receive(:id).and_return(12)
      Aws.should_receive(:bucket_name).and_return("bucket")
      file = {:contents => [{:key => "file1"}, {:key => "file2"}]}
      s3 = mock("s3")
      s3.should_receive(:incrementally_list_bucket).with("bucket", { 'prefix' => "12/out" }).and_yield(file)
      Aws.should_receive(:s3i).and_return(s3)
    end

    it "should return an array of filenames" do
      @job.output_files.should == ["file1", "file2"]
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

  describe "when creating the local zip file" do
    before(:each) do
      Object.send(:remove_const, 'Job')
      load 'job.rb'
      @job.id = 12
    end
    it "should have an id partition" do
      @job.id_partition.should eql("000/000/012")
    end

    it "should have a local datafile directory" do
      @job.local_datafile_directory.should match(/\/public\/jobs\/000\/000\/012\//)
    end

    it "should have a local zipfile" do
      @job.local_zipfile.should match(/\/public\/jobs\/000\/000\/012\/jobname.zip/)
    end
  end

  describe "creating a parameter file" do
    it "should create tandem parameter file for searcher Tandem" do
      @tandem = mock_model(TandemParameterFile)
      @tandem.should_receive(:write_file).with(/jobs\/000\/000\/000/).and_return(true)
      TandemParameterFile.should_receive(:find).with(1).and_return(@tandem)
      @job = create_job(:searcher => "tandem")
      @job.create_parameter_file
    end

    it "should create a omssa parameter file for searcher OMSSA" do
      @omssa = mock_model(OmssaParameterFile)
      @omssa.should_receive(:write_file).with(/jobs\/000\/000\/000/).and_return(true)
      OmssaParameterFile.should_receive(:find).with(1).and_return(@omssa)
      @job.create_parameter_file
    end
  end

  describe "set defaults" do
    before(:each) do
      Digest::SHA1.stub!(:hexdigest).and_return("hex")
      @job.set_defaults
    end
    it "should set the datafile name" do
      @job.datafile.should eql("pending-jobs/jobname.zip")
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

  describe "bundle datafile" do
    before(:each) do
      @zipfile = mock("zipfile")
      @zipfile.should_receive(:add).once.with("mgf_file", /mgf_file/).and_return(true)
      @zipfile.should_receive(:add).once.with("parameters.conf", /parameters.conf/).and_return(true)
      Zip::ZipFile.should_receive(:open).with(/jobname.zip/, 1).and_yield(@zipfile)
    end

    it "should delete the existing zipfile" do
      File.should_receive(:exist?).once.and_return(true)
      File.should_receive(:delete).once.and_return(true)
      @job.bundle_datafile
    end

    it "should create a zip file" do
      File.should_receive(:exist?).and_return(false)
      @job.bundle_datafile
    end
  end

  describe "upload data file to s3" do
    it "should put the zip file on s3" do
      @job.should_receive(:zipfile_name).and_return("zipfile_name")
      @job.should_receive(:local_zipfile).and_return("local_zipfile")
      @job.should_receive(:send_file).with("pending-jobs/zipfile_name","local_zipfile").and_return(true)
      @job.upload_datafile_to_s3.should be_true
    end
  end

  describe "send_background_upload_message" do
    it "should send a background upload head message" do
      @job.should_receive(:id).and_return(12)
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => BACKGROUNDUPLOAD, :job_id => 12}.to_yaml, :priority => 50, :ttr => 600).and_return(true)
      @job.send_background_upload_message
    end
  end

  describe "send message" do
    before(:each) do
      @job.should_receive(:output_file).and_return("file")
      @job.should_receive(:id).and_return(12)
      @job.should_receive(:spectra_count).and_return(100)
      @job.should_receive(:priority).and_return(1000)
      @job.should_receive(:datafile).and_return("datafile")
      Aws.should_receive(:bucket_name).and_return("bucket")
    end
    it "should send a pack node message" do
      MessageQueue.should_receive(:put).with(:name => 'node', :message => {:type => PACK, :bucket_name => "bucket", :job_id => 12, :datafile => "datafile", :output_file => "file", :searcher => "omssa", :spectra_count => 100, :priority => 1000}.to_yaml, :priority => 50, :ttr => 600).and_return(true)
      @job.send_message(PACK)
    end

    it "should send an unpack node message" do
      MessageQueue.should_receive(:put).with(:name => 'node', :message => {:type => UNPACK, :bucket_name => "bucket", :job_id => 12, :datafile => "datafile", :output_file => "file", :searcher => "omssa", :spectra_count => 100, :priority => 1000}.to_yaml, :priority => 50, :ttr => 600).and_return(true)
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

    it "should retry the upload until successful" do
      Time.stub!(:now).and_return(1.0)
      @job.should_receive(:upload_manifest).twice.and_return(false, true)
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
      @job.should_receive(:create_parameter_file).and_return(true)
      @job.should_receive(:bundle_datafile).and_return(true)
      @job.should_receive(:upload_datafile_to_s3).and_return(true)
      @job.should_receive(:send_message).with(UNPACK).and_return(true)
      @job.background_s3_upload
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

  protected
    def create_job(options = {})
      record = Job.new({ :name => "jobname", :mgf_file_name => 'mgf_file', :mgf_content_type => 'text/plain', :mgf_file_size => 20, :searcher => "omssa", :parameter_file_id => 1, :spectra_count => 200, :priority => 1000 }.merge(options))
      record
    end
end
