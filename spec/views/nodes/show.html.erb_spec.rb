require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/nodes/show.html.erb" do
  include NodesHelper
  
  before(:each) do
    @node = mock_model(Node)
    @node.stub!(:instance_id).and_return("MyString")
    @node.stub!(:chunks).and_return([])
    assigns[:node] = @node

    @aws_node = mock("AwsNode")
    @aws_node.stub!(:[]).and_return("")
    assigns[:aws_node] = @aws_node

  end

  it "should render attributes" do
    render "/nodes/show.html.erb"
    response.should have_text(/MyString/)
  end
end

