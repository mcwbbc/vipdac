require File.dirname(__FILE__) + '/../spec_helper'

describe Tandem do
  before(:each) do
    File.should_receive(:read).with("parameter").and_return("parametersfortandem")
    @tandem = create_tandem
  end

  describe "write paramter file" do
    it "should create a new parameter file" do
      file = mock("file")
      File.should_receive(:open).with(/pipeline\/tmp-(\d+?)\/input.xml/, File::RDWR|File::CREAT).and_yield(file)
      file.should_receive(:<<).with(/outputfilefortandem/).and_return(true)
      @tandem.write_parameter_file
    end
  end

  describe "update paramter xml string" do
    it "should substitute the parameters" do
      @tandem.build_parameter_string.should match(/parametersfortandem/)
    end
    it "should substitute the input file" do
      @tandem.build_parameter_string.should match(/inputfilefortandem/)
    end
    it "should substitute the output file" do
      @tandem.build_parameter_string.should match(/outputfilefortandem/)
    end
  end

  describe "run" do
    it "should do the steps" do
      @tandem.should_receive(:write_parameter_file).and_return(true)
      Tandem.should_receive(:run_commandline_application).and_return(true)
      @tandem.run
    end
  end

  describe "run commandline application" do
    it "should run tandem.exe" do
      Tandem.should_receive(:`).and_return(true)
      Tandem.run_commandline_application.should be_true
    end
  end

  protected
    def create_tandem
      record = Tandem.new("parameter", "inputfilefortandem", "outputfilefortandem")
      record
    end


end
