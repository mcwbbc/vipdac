require File.dirname(__FILE__) + '/../spec_helper'

describe Worker do
  
  before(:each) do
    @worker = create_worker
  end

  describe "initialize" do
    it "should accept a message" do
      @worker.message[:type].should == PROCESS
    end
  end

  describe "run" do
    describe "with a pack message" do
      it "should run the packer" do
        @worker = create_worker(:type => PACK)
        @worker.should_receive(:make_directory).and_return(true)      
        @worker.should_receive(:remove_item).and_return(true)      
        @worker.should_receive(:launch_packer).and_return(true)
        @worker.run
      end
    end
    describe "with an unpack message" do
      it "should run the unpacker" do
        @worker = create_worker(:type => UNPACK)
        @worker.should_receive(:make_directory).and_return(true)      
        @worker.should_receive(:remove_item).and_return(true)      
        @worker.should_receive(:launch_unpacker).and_return(true)
        @worker.run
      end
    end
    describe "with a process message" do
      it "should run the processor" do
        @worker = create_worker(:type => PROCESS)
        @worker.should_receive(:make_directory).and_return(true)      
        @worker.should_receive(:remove_item).and_return(true)      
        @worker.should_receive(:launch_process).and_return(true)
        @worker.run
      end
    end
  end

  describe "launch packer" do
    before(:each) do
      @packer = mock_model(Packer)
      @packer.should_receive(:run).and_return(true)
    end
    describe "omssa" do
      it "should create and run the packer" do
        OmssaPacker.should_receive(:new).and_return(@packer)
        @worker.should_receive(:send_message).with(JOBPACKING, 0.0, 0.0).and_return(true)
        @worker.should_receive(:send_message).with(JOBPACKED, 0.0, 0.0).and_return(true)
        @worker.launch_packer.should be_true
      end
    end
    describe "tandem" do
      it "should create and run the packer" do
        @worker = create_worker(:searcher => "tandem")
        TandemPacker.should_receive(:new).and_return(@packer)
        @worker.should_receive(:send_message).with(JOBPACKING, 0.0, 0.0).and_return(true)
        @worker.should_receive(:send_message).with(JOBPACKED, 0.0, 0.0).and_return(true)
        @worker.launch_packer.should be_true
      end
    end
  end

  describe "launch unpacker" do
    it "should run the unpacker" do
      @unpacker = mock_model(Unpacker)
      @unpacker.should_receive(:run).and_return(true)
      Unpacker.should_receive(:new).and_return(@unpacker)
      @worker.launch_unpacker.should be_true
    end
  end

  describe "download search database" do
    it "should download and re-write taxonomy if we don't have it" do
      SearchDatabase.should_receive(:missing_on_node?).with("search_database").and_return(true)
      SearchDatabase.should_receive(:download_to_node).with("search_database").and_return(true)
      SearchDatabase.should_receive(:write_taxonomy_file).and_return(true)
      @worker.download_search_database("search_database").should be_true
    end

    it "should do nothing if we do have it" do
      SearchDatabase.should_receive(:missing_on_node?).with("search_database").and_return(false)
      @worker.download_search_database("search_database").should be_nil
    end
  end

  describe "launch process" do
    it "should process the chunk without issue" do
      @worker.should_receive(:download_search_database).with("search_database").ordered.and_return(true)
      Time.stub!(:now).and_return(1)
      @worker.should_receive(:download_file).with(/\/filename$/, /filename$/).and_return(true)
      @worker.should_receive(:download_file).with(/parameter_filename$/, /parameter_filename$/).and_return(true)
      @worker.should_receive(:send_message).with(START, 1.0, 0.0).and_return(true)
      @worker.should_receive(:process_file).and_return(true)
      @worker.should_receive(:upload_output_file).and_return(true)
      @worker.should_receive(:send_message).with(FINISH, 1.0, 1.0).and_return(true)
      @worker.launch_process
    end
  end

  describe "process file" do
    describe "omssa" do
      it "should create a new ommsa searcher" do
        @searcher = mock_model(Omssa)
        @searcher.should_receive(:run).and_return(true)
        Omssa.should_receive(:new).with(/parameter_filename$/, /filename$/, /filename-out\.csv$/).and_return(@searcher)
        @worker.process_file
      end
    end
    describe "tandem" do
      it "should create a new tandem searcher" do
        @worker = create_worker(:searcher => "tandem")
        @searcher = mock_model(Tandem)
        @searcher.should_receive(:run).and_return(true)
        Tandem.should_receive(:new).with(/parameter_filename$/, /filename$/, /filename-out\.xml$/).and_return(@searcher)
        @worker.process_file
      end
    end
  end

  describe "upload output file" do
    it "should put the output file back onto s3" do
      @worker.should_receive(:send_file).with("hash_key/out/filename-out.csv", %r|/pipeline/tmp-(\d+?)/filename-out.csv|).and_return(true)
      @worker.upload_output_file
    end
  end

  describe "send message" do
    before(:each) do
      Aws.should_receive(:instance_id).and_return("instance")
      Aws.should_receive(:bucket_name).and_return("bucket")
    end

    it "should send a start node message" do
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => START, :bytes => 10, :filename => "filename", :parameter_filename => "parameter_filename", :sendtime => 1.0, :chunk_key => "key", :job_id => 12, :bucket_name => "bucket", :instance_id => "instance-#{$$}", :starttime => 2.0, :finishtime => 0.0}.to_yaml, :priority => 100, :ttr => 60).and_return(true)
      @worker.send_message(START, 2.0, 0.0)
    end

    it "should send a finish node message" do
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => FINISH, :bytes => 10, :filename => "filename", :parameter_filename => "parameter_filename", :sendtime => 1.0, :chunk_key => "key", :job_id => 12, :bucket_name => "bucket", :instance_id => "instance-#{$$}", :starttime => 2.0, :finishtime => 3.0}.to_yaml, :priority => 100, :ttr => 60).and_return(true)
      @worker.send_message(FINISH, 2.0, 3.0)
    end

    it "should send a job packing" do
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => JOBPACKING, :bytes => 10, :filename => "filename", :parameter_filename => "parameter_filename", :sendtime => 1.0, :chunk_key => "key", :job_id => 12, :bucket_name => "bucket", :instance_id => "instance-#{$$}", :starttime => 0.0, :finishtime => 0.0}.to_yaml, :priority => 100, :ttr => 60).and_return(true)
      @worker.send_message(JOBPACKING, 0.0, 0.0)
    end
    it "should send a job packed" do
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => JOBPACKED, :bytes => 10, :filename => "filename", :parameter_filename => "parameter_filename", :sendtime => 1.0, :chunk_key => "key", :job_id => 12, :bucket_name => "bucket", :instance_id => "instance-#{$$}", :starttime => 0.0, :finishtime => 0.0}.to_yaml, :priority => 100, :ttr => 60).and_return(true)
      @worker.send_message(JOBPACKED, 0.0, 0.0)
    end
  end

  describe "local output filename" do
    describe "for omssa" do
      it "should be csv" do
        @worker.local_output_filename.should match(/-out\.csv/)
      end
    end
    describe "for tandem" do
      it "should be xml" do
        @worker = create_worker(:searcher => "tandem")
        @worker.local_output_filename.should match(/-out\.xml/)
      end
    end
  end

  describe "local input filename" do
    it "should return a filename" do
      @worker.local_input_filename.should match(%r|pipeline/tmp-(\d+?)/filename|)
    end
  end

  describe "local parameter filename" do
    it "should return a filename" do
      @worker.local_parameter_filename.should match(%r|pipeline/tmp-(\d+?)/parameter_filename|)
    end
  end
  
  protected
    def create_worker(options = {})
      record = Worker.new({ :type => PROCESS, :chunk_count => 1, :bytes => 10, :sendtime => 1.0, :chunk_key => "key", :job_id => 12, :hash_key => 'hash_key', :searcher => "omssa", :search_database => "search_database", :filename => "filename", :bucket_name => "bucket_name", :parameter_filename => "parameter_filename"}.merge(options))
      record
    end

end
