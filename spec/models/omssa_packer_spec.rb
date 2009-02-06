require File.dirname(__FILE__) + '/../spec_helper'

describe OmssaPacker do

  before(:each) do
    @packer = create_packer
  end

  describe "create ez2 file" do
    it "should return an ez2 filename based on the zipfile name" do
      @packer.local_ez2file.should match(/resultfilename$/)
    end

    it "should create an input string" do
      @packer.ez2_input.should match(/--input=\/pipeline\/tmp-(.+?)\/pack$/)
    end

    it "should create an output string" do
      @packer.ez2_output.should match(/--output=(.+?)resultfilename$/)
    end

    it "should create a mgf string" do
      Dir.should_receive(:[]).and_return(["/pipeline/tmp-123/ct4-partial.mgf"])
      @packer.ez2_mgf.should match(/--mgf=\/pipeline\/tmp-.+\/ct4-partial.mgf/)
    end

    it "should create a db string" do
      File.should_receive(:read).with(/\/pipeline\/tmp-(.+)\/pack\/parameters.conf/).and_return("-d /pipeline/dbs/25.H_sapiens -e 1")
      @packer.ez2_db.should eql("--db=/pipeline/dbs/25.H_sapiens")
    end

    it "should create a mods string" do
      @packer.ez2_mods.should eql("--mods=/pipeline/bin/omssa/mods.xml")
    end

    describe "assemble omssa_aws2ez2_unix parameter string" do
      it "should assemble the parameter string" do
        @packer = create_packer(:output_file => "file")
        @packer.should_receive(:ez2_input).and_return("--input=/input")
        @packer.should_receive(:ez2_output).and_return("--output=/output")
        @packer.should_receive(:ez2_mgf).and_return("--mgf=/mgf")
        @packer.should_receive(:ez2_db).and_return("--db=/db")
        @packer.should_receive(:ez2_mods).and_return("--mods=/mods")
        @packer.ez2_parameter_string.should eql("--input=/input --output=/output --mgf=/mgf --db=/db --mods=/mods")
      end
    end
    
    it "should run the omssa_aws2ez2_unix script" do
      @packer.should_receive(:run_omssa_aws2ez2_unix).with("hello").and_return(true)
      @packer.run_omssa_aws2ez2_unix("hello")
    end

    it "should run the perl script to generate an ez2 file" do
      @packer.should_receive(:ez2_parameter_string).and_return("string")
      OmssaPacker.should_receive(:run_omssa_aws2ez2_unix).with("string").and_return(true)
      @packer.generate_ez2_file
    end
  end

  describe "run omssa aws2ez2 unix" do
    it "should run the perl file" do
      OmssaPacker.should_receive(:`).with(/omssa_aws2ez2_unix\.pl/).and_return(true)
      OmssaPacker.run_omssa_aws2ez2_unix("file").should be_true
    end
  end

  def run
    begin
      make_directory(PACK_DIR)
      download_results_files
      download_file(local_mgf_file, remote_mgf_file)
      download_file(local_parameter_file, remote_parameter_file)
      generate_ez2_file
      zip_files
      send_file(bucket_object(local_zipfile), local_zipfile) # this will upload the file
    end
    ensure
      remove_item(PACK_DIR)
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
      @packer.should_receive(:send_file).with("resultfiles/resultfilename.zip", /pack\/resultfilename\.zip$/).ordered.and_return(true)
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

  protected
    def create_packer(options = {})
      record = OmssaPacker.new({:type => PACK, :bucket_name => "bucket", :job_id => 1234, :hash_key => "hash_key", :datafile => "datafile.mgf", :resultfile_name => "resultfilename", :searcher => "omssa"}.merge(options))
      record
    end

end
