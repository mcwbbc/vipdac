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

  describe "local_manifest" do
    it "should return the local manifest string" do
      @packer.local_manifest.should match(/^\/pipeline\/tmp-.+\/pack\/manifest.yml$/)
    end
  end

  describe "manifest" do
    it "should download a manifest.yml file from s3" do
      @packer.should_receive(:local_manifest).twice.and_return("local_manifest")
      @packer.should_receive(:download_file).with("local_manifest", "hash_key/manifest.yml").and_return(true)
      YAML.should_receive(:load_file).with("local_manifest").and_return("hello")
      @packer.manifest.should == "hello"
    end
  end

  describe "local zipfile" do
    it "should return the zipfile name" do
      @packer = create_packer(:output_file => "file")
      @packer.local_zipfile.should match(/^\/pipeline\/tmp-.+\/pack\/file$/)
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

  def download_results_files
    manifest.each do |file|
      download_file("#{PACK_DIR}/"+input_file(file), file)
    end
  end

  describe "download results files" do
    it "should download the results files from s3 and write it out" do
      @packer.should_receive(:manifest).and_return(["filename"])
      @packer.should_receive(:input_file).with("filename").and_return("input_file")
      @packer.should_receive(:download_file).with(/^\/pipeline\/tmp-.+\/pack\/input_file$/, "filename").and_return(true)
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
      @packer.should_receive(:local_zipfile).twice.and_return("local_zipfile")
      @packer.should_receive(:zip_files).and_return(true)
      @packer.should_receive(:send_file).with("completed-jobs/local_zipfile", "local_zipfile").and_return(true)
      @packer.should_receive(:remove_item).and_return(true)
      @packer.run
    end
  end

  protected
    def create_packer(options = {})
      record = Packer.new({:type => PACK, :bucket_name => "bucket", :job_id => 12, :hash_key => 'hash_key', :datafile => "datafile", :output_file => "output_file", :searcher => "omssa"}.merge(options))
      record
    end

end
