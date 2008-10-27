require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/nodes/index.html.erb" do
  include NodesHelper
  
  before(:each) do
    @nodes = []
    
    Aws.stub!(:instance_id).and_return("1")
    0.upto(2) do |i|
      node = mock_model(Node)
      node.stub!(:instance_id).and_return("#{i}")
      node.stub!(:instance_type).and_return("m1.small")
      node.stub!(:created_at).and_return(1.0)
      @nodes << node
    end 

    @nodes.stub!(:size).and_return(2)
    @aws_nodes.stub!(:size).and_return(2)
    assigns[:nodes] = @nodes
  end

  it "should render list of nodes" do
    render "/nodes/index.html.erb"
  end

end

