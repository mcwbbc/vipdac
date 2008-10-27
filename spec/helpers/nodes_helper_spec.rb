require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include ApplicationHelper
include NodesHelper

describe NodesHelper do
  before(:each) do
    @node = mock_model(Node)
    @node.stub!(:[]).with(:aws_state).and_return("state")
    @node.stub!(:[]).with(:aws_reason).and_return("reason")
    @node.stub!(:[]).with(:aws_image_id).and_return("ami")
    @node.stub!(:[]).with(:dns_name).and_return("dns")
    @node.stub!(:[]).with(:aws_launch_time).and_return("launch")
  end

  describe "aws params" do
    it "should return strings for aws parameters" do
      text = aws_params(@node)
      text.should match(/State: state/)
      text.should match(/AMI: ami/)
      text.should match(/Launch Time: launch/)
    end
  end

  describe "row color" do
    it "should return 'complete' for running" do
      row_color("running").should eql("complete")
    end
    it "should return 'created' for terminated" do
      row_color("terminated").should eql("created")
    end
    it "should return 'working' for anything else" do
      row_color("cheese").should eql("working")
    end
  end
  
end

