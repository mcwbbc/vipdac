require File.dirname(__FILE__) + '/../spec_helper'

describe Unpacker do
  before(:each) do
    @unpacker = create_unpacker
  end

  describe "initalize" do
    it "should set the message" do
      @unpacker.message[:bucket_name].should eql("bucket")
    end
  end
  
  describe "local zipfile" do
    it "should return a filename string" do
      @unpacker.local_zipfile.should match(/unpack\/data.zip/)
    end
  end

  describe "local parameter file" do
    it "should return a filename string" do
      @unpacker.local_parameter_file.should match(/unpack\/parameters.conf/)
    end
  end

  describe "bucket object" do
    it "should return a string for the filepath" do
      @unpacker.bucket_object("string").should eql("hash_key/string")
    end

    it "should return a last item split by /" do
      @unpacker.bucket_object("1/2/3/string").should eql("hash_key/string")
    end
  end

  describe "mgf filename" do
    it "should return the first mgf filename in the unpack dir" do
      Dir.should_receive(:[]).and_return(["this.mgf", "that.mgf", "another.mgf"])
      @unpacker.mgf_filename.should == "this.mgf"
    end
  end

  describe "mgf filenames" do
    it "should return an array of mgf files" do
      Dir.should_receive(:[]).and_return(["this.mgf", "that.mgf", "another.mgf"])
      @unpacker.mgf_filenames.should == ["this.mgf", "that.mgf", "another.mgf"]
    end
  end

  describe "send job message" do
    it "should send a message to the head queue" do
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => "message", :job_id => 12}.to_yaml, :priority => 100, :ttr => 60).and_return(true)
      @unpacker.send_job_message("message").should be_true
    end
  end

  describe "send created messages" do
    it "should send a message to the created queue" do
      File.should_receive(:size).and_return(1234)
      Time.stub!(:now).and_return(1)
      Digest::SHA1.should_receive(:hexdigest).and_return("hex")
      @unpacker.should_receive(:mgf_filenames).and_return(["filename"])
      msg = {:type => CREATED, :chunk_count => 1, :bytes => 1234, :sendtime => 1.0, :chunk_key => "hex", :job_id => 12, :filename => "hash_key/file", :parameter_filename => "hash_key/parameters.conf", :bucket_name => "bucket", :searcher => "omssa"}.to_yaml
      MessageQueue.should_receive(:put).with(:name => 'head', :message => msg, :priority => 10, :ttr => 60).and_return(true)
      @unpacker.send_created_message("file").should be_true
    end
  end

  describe "update split mgf files" do
    it "should send a file to s3" do
      @unpacker.should_receive(:mgf_filenames).and_return(["filename"])
      @unpacker.should_receive(:send_file).with("hash_key/filename", "filename").and_return(true)
      @unpacker.should_receive(:send_created_message).with("filename").and_return(true)
      @unpacker.upload_split_mgf_files
    end
  end

  describe "run" do
    it "should complete all the steps" do
      @unpacker.should_receive(:send_job_message).twice.and_return(true)
      @unpacker.should_receive(:make_directory).and_return(true)
      @unpacker.should_receive(:download_file).and_return(true)
      @unpacker.should_receive(:unzip_file).and_return(true)
      @unpacker.should_receive(:split_original_mgf).and_return(true)
      @unpacker.should_receive(:local_parameter_file).twice.and_return("parameters.conf")
      @unpacker.should_receive(:send_file).with("hash_key/parameters.conf", "parameters.conf").and_return(true)
      @unpacker.should_receive(:upload_split_mgf_files).and_return(true)
      @unpacker.should_receive(:remove_item).and_return(true)
      @unpacker.run
    end
  end

  describe "splitting the mgf file" do
    before(:each) do
      @unpacker.stub!(:mgf_filename).and_return("filename.mgf")
      Dir.should_receive(:mkdir).and_return(true)
    end

    describe "directory management" do
      before(:each) do
        file_contents = ["BEGIN IONS","TITLE=060121Yrasprg051025-ct4.1451.1451.1.dta","CHARGE=1+","PEPMASS=707.2231","395.1292 32126.4","END IONS"]
        File.should_receive(:open).with("filename.mgf").and_return(file_contents)
        outfile = mock("outfile")
        outfile.should_receive(:write).with(file_contents.to_s).and_return(true)
        File.should_receive(:open).with(/unpack\/mgfs\/filename-(.+).mgf/, 'w').and_yield(outfile)
      end
      it "should remove the mgf directory if it exists" do
        File.should_receive(:exists?).and_return(true, false)
        FileUtils.should_receive(:rm_r).and_return(true)
        @unpacker.split_original_mgf
      end

      it "should not remove the mgf directory if it doesn't exist" do
        File.should_receive(:exists?).and_return(false, false)
        FileUtils.should_not_receive(:rm_r)
        @unpacker.split_original_mgf
      end
    end

    it "should write two files for more than 200 ions" do
      file_contents = ["BEGIN IONS","TITLE=060121Yrasprg051025-ct4.1451.1451.1.dta","CHARGE=1+","PEPMASS=707.2231","395.1292 32126.4","END IONS"]
      big_file = []
      201.times do
        big_file << file_contents
      end
      big_file.flatten!
      File.should_receive(:open).with("filename.mgf").and_return(big_file)
      outfile = mock("outfile")
      outfile.should_receive(:write).with(big_file[0..1199].to_s).and_return(true)
      File.should_receive(:open).with(/unpack\/mgfs\/filename-0000.mgf/, 'w').and_yield(outfile)

      outfile2 = mock("outfile2")
      outfile2.should_receive(:write).with(big_file[1200..1205].to_s).and_return(true)
      File.should_receive(:open).with(/unpack\/mgfs\/filename-0001.mgf/, 'w').and_yield(outfile2)
      @unpacker.split_original_mgf
    end

    it "should write two files for more than 100 ions" do
      @unpacker = create_unpacker(:spectra_count => 100)
      @unpacker.stub!(:mgf_filename).and_return("filename.mgf")
      file_contents = ["BEGIN IONS","TITLE=060121Yrasprg051025-ct4.1451.1451.1.dta","CHARGE=1+","PEPMASS=707.2231","395.1292 32126.4","END IONS"]
      big_file = []
      101.times do
        big_file << file_contents
      end
      big_file.flatten!
      File.should_receive(:open).with("filename.mgf").and_return(big_file)
      outfile = mock("outfile")
      outfile.should_receive(:write).with(big_file[0..599].to_s).and_return(true)
      File.should_receive(:open).with(/unpack\/mgfs\/filename-0000.mgf/, 'w').and_yield(outfile)

      outfile2 = mock("outfile2")
      outfile2.should_receive(:write).with(big_file[600..605].to_s).and_return(true)
      File.should_receive(:open).with(/unpack\/mgfs\/filename-0001.mgf/, 'w').and_yield(outfile2)
      @unpacker.split_original_mgf
    end

  end

  describe "writing the output file" do
    it "should take a filename and output a file" do
      outfile = mock("outfile")
      outfile.should_receive(:write).with("text").and_return(true)
      File.should_receive(:open).with("filename", 'w').and_yield(outfile)
      @unpacker.write_file("filename", "text")
    end
  end

  protected
    def create_unpacker(options = {})
      record = Unpacker.new({:type => UNPACK, :bucket_name => "bucket", :job_id => 12, :hash_key => 'hash_key', :datafile => "datafile", :searcher => "omssa", :spectra_count => 200}.merge(options))
      record
    end

end
