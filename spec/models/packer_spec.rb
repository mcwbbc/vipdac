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
      @packer = create_packer
      @packer.local_zipfile.should match(/^\/pipeline\/tmp-.+\/pack\/result_file.zip$/)
    end
  end

  describe "bucket object" do
    it "should return a filename string" do
      @packer.bucket_object("dir/result_file.zip").should == "resultfiles/result_file.zip"
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
      @packer = create_packer(:output_file => "file-results.zip")
      @packer.should_receive(:make_directory).with(PACK_DIR).ordered.and_return(true)
      @packer.should_receive(:download_results_files).ordered.and_return(true)
      @packer.should_receive(:download_file).with(/pack\/datafile\.mgf$/, "datafiles/datafile.mgf").ordered.and_return(true)
      @packer.should_receive(:download_file).with(/pack\/parameters\.conf$/, "hash_key/parameters.conf").ordered.and_return(true)
      @packer.should_receive(:generate_ez2_file).ordered.and_return(true)
      @packer.should_receive(:zip_files).ordered.and_return(true)
      @packer.should_receive(:send_file).with("resultfiles/result_file.zip", /pack\/result_file\.zip$/).ordered.and_return(true)
      @packer.should_receive(:remove_item).with(/\/pipeline\/tmp-(.+?)\/pack/).and_return(true)
      @packer.run
    end
  end

  describe "local mgf file" do
    it "should return a filename string" do
      @packer.local_mgf_file.should match(/pack\/datafile\.mgf$/)
    end
  end

  describe "local parameter file" do
    it "should return a filename string" do
      @packer.local_parameter_file.should match(/pack\/parameters\.conf$/)
    end
  end

  it "should create an input string" do
    @packer.ez2_input.should match(/--input=\/pipeline\/tmp-(.+?)\/pack$/)
  end

  it "should create an output string" do
    @packer.ez2_output.should match(/--output=(.+?)result_file$/)
  end

  protected
    def create_packer(options = {})
      record = Packer.new({:type => PACK, :bucket_name => "bucket", :job_id => 12, :hash_key => 'hash_key', :datafile => "datafile.mgf", :resultfile_name => "result_file", :searcher => "omssa"}.merge(options))
      record
    end

end
