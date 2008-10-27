require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApplicationHelper
include JobsHelper

describe JobsHelper do
  before(:each) do
    @job = mock_model(Job)
  end

  describe "complete_bar" do
    it "should return 'N/A' if there are no chunks" do
      chunks = []
      @job.should_receive(:chunks).and_return(chunks)
      complete_bar(@job).should == "N/A"
    end

    describe "matching percentage" do
      before(:each) do
        @chunk = mock_model(Chunk)
        @chunk.stub!(:chunk_count).and_return(1)

        @chunks = mock("chunks")
        @chunks.stub!(:first).and_return(@chunk)
        @chunks.stub!(:complete).and_return([@chunk])
        @chunks.stub!(:empty?).and_return(false)

        @job.should_receive(:chunks).exactly(3).times.and_return(@chunks)
      end

      it "should return a string with '100%' for the chunks" do
        text = complete_bar(@job)      
        text.should match(/100%/)
      end

      it "should return a string with '50%' for the chunks" do
        @chunk.stub!(:chunk_count).and_return(2)
        text = complete_bar(@job)      
        text.should match(/50%/)
      end
    end
  end
end
