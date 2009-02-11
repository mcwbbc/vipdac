require File.dirname(__FILE__) + '/../spec_helper'

describe TandemPacker do

  describe "assemble tandem_aws2ez2_unix parameter string" do
    it "should assemble the parameter string" do
      packer = create_packer(:output_file => "file")
      packer.should_receive(:ez2_input).and_return("--input=/input")
      packer.should_receive(:ez2_output).and_return("--output=/output")
      packer.ez2_parameter_string.should eql("--input=/input --output=/output")
    end
  end

  describe "run tandem aws2ez2 unix" do
    it "should run the perl file" do
      TandemPacker.should_receive(:`).with(/tandem_aws2ez2_unix\.pl/).and_return(true)
      TandemPacker.run_tandem_aws2ez2_unix("file").should be_true
    end
  end

  it "should run the perl script to generate an ez2 file" do
    packer = create_packer
    packer.should_receive(:ez2_parameter_string).and_return("string")
    TandemPacker.should_receive(:run_tandem_aws2ez2_unix).with("string").and_return(true)
    packer.generate_ez2_file
  end

  protected
    def create_packer(options = {})
      record = TandemPacker.new({:type => PACK, :bucket_name => "bucket", :job_id => 1234, :hash_key => "hash_key", :datafile => "datafile.mgf", :resultfile_name => "resultfilename", :searcher => "omssa"}.merge(options))
      record
    end

end
