require File.dirname(__FILE__) + '/../spec_helper'

describe Omssa do
  before(:each) do
    File.should_receive(:read).with("parameter").and_return("parameters")
    @omssa_searcher = create_omssa_searcher
  end
  
  describe "running omssa command line" do
    it "should run the ommsa application" do
      @omssa_searcher.should_receive(:`).with(/omssacl/).and_return(true)
      @omssa_searcher.run
    end
  end

  protected
    def create_omssa_searcher
      record = Omssa.new("parameter", "input", "output")
      record
    end

end
