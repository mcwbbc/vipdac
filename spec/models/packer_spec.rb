require File.dirname(__FILE__) + '/../spec_helper'

describe Packer do

  before(:each) do
    @packer = create_packer({:text => "hello"})
  end

  describe "initialize" do
    it "should accept a message" do
      @packer.message[:text].should == "hello"
    end
  end

  describe "manifest" do
    it "should download a manifest.yml file from s3" do
      Aws.should_receive(:bucket_name).and_return("name")
      string = "hello"
      s3 = mock("s3")
      s3.should_receive(:get_object).and_return(string)      
      Aws.should_receive(:s3i).and_return(s3)
      @packer.manifest.should == "hello"
    end
  end

  describe "cleanup pack" do
    it "should remove the pack directory" do
      File.should_receive(:exists?).and_return(true)
      FileUtils.should_receive(:rm_r).and_return(true)
      @packer.remove_item("dir")
    end

    it "should not remove the pack directory" do
      File.should_receive(:exists?).and_return(false)
      FileUtils.should_not_receive(:rm_r).and_return(true)
      @packer.remove_item("dir")
    end
  end

  describe "local zipfile" do
    it "should return the zipfile name" do
      @packer = create_packer(:output_file => "file")
      @packer.local_zipfile.should match(/pipeline\/tmp-.+\/pack\/file/)
    end
  end

  describe "make directory" do
    it "should create the pack directory" do
      File.should_receive(:exists?).and_return(false)
      Dir.should_receive(:mkdir).and_return(true)
      @packer.make_directory("test")
    end

    it "should not create the pack directory" do
      File.should_receive(:exists?).and_return(true)
      Dir.should_not_receive(:mkdir).and_return(true)
      @packer.make_directory("test")
    end
  end

  describe "send job message" do
    it "should send an Aws message" do
      @packer = create_packer(:job_id => 1)
      Aws.should_receive(:bucket_name).and_return("name")
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => DOWNLOAD, :job_id => 1, :bucket_name => "name"}.to_yaml, :priority => 100).and_return(true)
      @packer.send_job_message.should be_true
    end
  end

  describe "send file" do
    it "should send a file to s3" do
      file = "dir/filename"
      File.should_receive(:open).and_return(true)
      Aws.should_receive(:put_object).and_return(true)
      @packer.send_file(file).should be_true
    end
  end

  describe "bucket object" do
    it "should return a filename string" do
      @packer.bucket_object("dir/file").should == "completed-jobs/file"
    end
  end

  describe "output filenames" do
    it "should return an array of files with the extensions" do
      Dir.should_receive(:[]).and_return(["this.xml", "that.csv", "another.conf"])
      @packer.output_filenames.should == ["this.xml", "that.csv", "another.conf"]
    end
  end

  describe "download results files" do
    it "should download the results files from s3 and write it out" do
      @packer.should_receive(:manifest).and_return(["filename"])
      chunk = mock_model(Chunk)
      s3 = mock("s3")
      s3.should_receive(:get).and_yield(chunk)
      file = mock("file")
      file.should_receive(:write).with(chunk).and_return(true)
      file.should_receive(:close).and_return(true)
      File.should_receive(:new).and_return(file)
      Aws.should_receive(:bucket_name).and_return("bucket")
      Aws.should_receive(:s3i).and_return(s3)
      @packer.download_results_files
    end
  end

  describe "zipping results files" do
    it "should create a zipfile with the results files" do
      @packer.should_receive(:output_filenames).and_return(["file"])
      @packer.should_receive(:local_zipfile).and_return("localzip.zip")
      zipfile = mock("zipfile")
      zipfile.should_receive(:add).with("file", "file").and_return(true)
      Zip::ZipFile.should_receive(:open).and_yield(zipfile)
      @packer.zip_files
    end
  end

  describe "run" do
    it "should complete all the steps" do
      @packer = create_packer(:output_file => "file")
      @packer.should_receive(:make_directory).and_return(true)
      @packer.should_receive(:download_results_files).and_return(true)
      @packer.should_receive(:zip_files).and_return(true)
      @packer.should_receive(:send_file).and_return(true)
      @packer.should_receive(:send_job_message).and_return(true)
      @packer.should_receive(:remove_item).and_return(true)
      @packer.run
    end
  end

  protected
    def create_packer(options = {})
      record = Packer.new({:type => PACK, :bucket_name => "bucket", :job_id => 12, :datafile => "datafile", :output_file => "output_file", :searcher => "omssa"}.merge(options))
      record
    end

end
