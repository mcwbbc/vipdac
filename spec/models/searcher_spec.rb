require File.dirname(__FILE__) + '/../spec_helper'

describe Searcher do

  before(:each) do
    File.should_receive(:read).with("parameter").and_return("parameters")
    @searcher = create_searcher
  end

  describe "initialize" do
    it "should set the parameter file" do
      @searcher.parameter_file.should== "parameter"
    end

    it "should set the input file" do
      @searcher.input_file.should== "input"
    end

    it "should set the output file" do
      @searcher.output_file.should== "output"
    end

    it "should set the parameters" do
      @searcher.parameters.should== "parameters"
    end
  end


  protected
    def create_searcher
      record = Searcher.new("parameter", "input", "output")
      record
    end

end
