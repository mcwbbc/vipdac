require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/nodes/new.html.erb" do
  include NodesHelper
  
  before(:each) do
    @node = mock_model(Node)
    @node.stub!(:new_record?).and_return(true)
    @node.stub!(:instance_type).and_return("m1.small")
    assigns[:node] = @node
  end

  it "should render new form" do
    render "/nodes/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", nodes_path) do
      with_tag("select#node_instance_type[name=?]", "node[instance_type]")
    end
  end
end


