require File.dirname(__FILE__) + '/../spec_helper'

describe OmssaPacker do

  before(:each) do
    @packer = create_packer
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

  describe "create ez2 file" do
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

  protected
    def create_packer(options = {})
      record = OmssaPacker.new({:type => PACK, :bucket_name => "bucket", :job_id => 1234, :hash_key => "hash_key", :datafile => "datafile.mgf", :resultfile_name => "resultfilename", :searcher => "omssa"}.merge(options))
      record
    end

end
