require File.dirname(__FILE__) + '/../spec_helper'

describe OmssaPacker do

  before(:each) do
    @packer = create_packer
  end

  describe "create ez2 file" do
    it "should return an ez2 filename based on the zipfile name" do
      @packer.local_ez2file.should match(/omssa-results$/)
    end

    it "should create an input string" do
      @packer.ez2_input.should match(/--input=\/pipeline\/tmp-(.+?)\/pack$/)
    end

    it "should create an output string" do
      @packer.ez2_output.should match(/--output=(.+?)omssa-results$/)
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

  describe "download datafile" do
    it "should download the original datafile" do
      @packer.should_receive(:download_file).with(/\/pipeline\/tmp-.+\/pack\/data.zip/, "datafile.zip").and_return(true)
      @packer.download_datafile
    end
  end

  describe "local datafile" do
    it "should be the unpack dir data.zip" do
      @packer.local_datafile.should match(/\/pipeline\/tmp-.+\/data.zip/)
    end
  end

  describe "run" do
    it "should complete all the steps" do
      @packer = create_packer(:output_file => "file")
      @packer.should_receive(:local_zipfile).and_return("local_zipfile")
      @packer.should_receive(:local_datafile).and_return("local_datafile")
      @packer.should_receive(:make_directory).with(PACK_DIR).and_return(true)
      @packer.should_receive(:download_results_files).and_return(true)
      @packer.should_receive(:download_datafile).and_return(true)
      @packer.should_receive(:unzip_file).with("local_datafile", PACK_DIR).and_return(true)
      @packer.should_receive(:zip_files).and_return(true)
      @packer.should_receive(:generate_ez2_file).and_return(true)
      @packer.should_receive(:send_file).with("local_zipfile").and_return(true)
      @packer.should_receive(:remove_item).with(/\/pipeline\/tmp-(.+?)\/pack/).and_return(true)
      @packer.run
    end
  end

  protected
    def create_packer(options = {})
      record = OmssaPacker.new({:type => PACK, :bucket_name => "bucket", :job_id => 1234, :datafile => "datafile.zip", :output_file => "omssa-results.zip", :searcher => "omssa"}.merge(options))
      record
    end

end
