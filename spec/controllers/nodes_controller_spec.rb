require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NodesController do

  before(:each) do
    @ec2_mock = mock("ec2")
    @ec2_mock.stub!(:describe_instances).and_return(['a', 'b', 'c'])
    @ec2_mock.stub!(:launch_instances).and_return([:aws_instance_id => 'ec2-instance'])
    @ec2_mock.stub!(:terminate_instances).and_return(true)

    Aws.stub!(:ec2).and_return(@ec2_mock)
    Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret'})
    Aws.stub!(:amis).and_return({'x86_64' => 'bigone', 'i386' => 'smallone'})
  end
  
  describe "handling GET /nodes" do

    before(:each) do
      @node = mock_model(Node)
      Node.stub!(:find).and_return([@node])
      @aws_nodes = []
      @active_nodes = []
      @nodes = [@node]
      @status_hash = {'1' => 'running', '2' => 'running', '3' => 'terminated'}
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all nodes" do
      Node.should_receive(:listing).and_return(@aws_nodes)
      Node.should_receive(:active_nodes).and_return(@active_nodes)
      Node.should_receive(:running).and_return(@nodes)
      Node.should_receive(:status_hash).and_return(@status_hash)
      do_get
    end
  
    it "should assign the found nodes for the view" do
      Node.should_receive(:listing).and_return(@aws_nodes)
      Node.should_receive(:active_nodes).and_return(@active_nodes)
      Node.should_receive(:running).and_return(@nodes)
      Node.should_receive(:status_hash).and_return(@status_hash)
      do_get
      assigns[:active_nodes].should == @active_nodes
      assigns[:aws_nodes].should == @aws_nodes
      assigns[:nodes].should == @nodes
      assigns[:status_hash].should == @status_hash
    end
  end

  describe "handling GET /nodes/aws" do

    before(:each) do
      @nodes = []
      0.upto(2) do |i|
        aws_node = {}
        aws_node[:aws_instance_id] = "id"
        aws_node[:aws_state] = "state"
        aws_node[:aws_reason] = "reason"
        aws_node[:dns_name] = "dnsname"
        aws_node[:aws_image_id] = "ami"
        aws_node[:aws_launch_time] = "time"
        @nodes << aws_node
      end
    end
  
    def do_get
      get :aws
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('aws')
    end
  
    it "should find all aws nodes" do
      Node.should_receive(:listing).and_return(@nodes)
      do_get
    end
  
    it "should assign the found nodes for the view" do
      Node.should_receive(:listing).and_return(@nodes)
      do_get
      assigns[:nodes].should == @nodes
    end
  end


  describe "handling GET /nodes/i-123345" do

    before(:each) do
      @node = mock_model(Node)
      Node.stub!(:find_by_instance_id).and_return(@node)
      @node.stub!(:describe).and_return({:aws_state => "pending"})
      @node.stub!(:instance_id).and_return("i-12345")
    end
  
    def do_get
      get :show, :id => "i-12345"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render show template" do
      do_get
      response.should render_template('show')
    end
  
    it "should find the node requested" do
      Node.should_receive(:find_by_instance_id).with("i-12345").and_return(@node)
      do_get
    end
  
    it "should assign the found node for the view" do
      do_get
      assigns[:node].should equal(@node)
    end

    it "should redirect to the index for an invalid node" do
      Node.stub!(:find_by_instance_id).and_return(nil)
      do_get
      response.should redirect_to(nodes_url)
    end

  end

  describe "handling GET /nodes/new" do

    before(:each) do
      @node = mock_model(Node)
      Node.stub!(:new).and_return(@node)
      Node.stub!(:launchable_nodes).and_return([["1", "1"]])
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new node" do
      Node.should_receive(:new).and_return(@node)
      do_get
    end
  
    it "should not save the new node" do
      @node.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new node for the view" do
      do_get
      assigns[:node].should equal(@node)
    end

    it "should assign the launchable nodes for the view" do
      do_get
      assigns[:launchable_nodes].should == [["1", "1"]]
    end
  end


  describe "handling POST /nodes" do
    before(:each) do
      @node1 = mock_model(Node, :to_param => "1")
      @node2 = mock_model(Node, :to_param => "2")
      @node3 = mock_model(Node, :to_param => "3")
      @node1.stub!(:launch).and_return(true) #don't need it going skynet on us again
      @node2.stub!(:launch).and_return(true) #don't need it going skynet on us again
      @node3.stub!(:launch).and_return(true) #don't need it going skynet on us again
    end

    def do_post
      post :create, :node => {"instance_type" => "c1.medium"}, "quantity" => "3"
    end

    describe "with successful save" do
      it "should create a number of nodes based on the quantity" do
        @node1.should_receive(:valid?).and_return(true)
        Node.should_receive(:new).exactly(4).times.with({"instance_type" => "c1.medium"}).and_return(@node1, @node1, @node2, @node3)
        @node1.should_receive(:save).and_return(true)
        @node2.should_receive(:save).and_return(true)
        @node3.should_receive(:save).and_return(true)
        @node1.should_receive(:launch).and_return(true)
        @node2.should_receive(:launch).and_return(true)
        @node3.should_receive(:launch).and_return(true)
        do_post
        response.flash[:notice].should == "3 Node(s) were successfully launched."
        response.should redirect_to(nodes_url)
      end
    end
    
    describe "with failed save" do
      it "should re-render 'new'" do
        @node1.should_receive(:valid?).and_return(false)
        Node.should_receive(:new).with({"instance_type" => "c1.medium"}).and_return(@node1)
        Node.stub!(:launchable_nodes).and_return(["1"])
        do_post
        response.should render_template('new')
        assigns[:launchable_nodes].should == ["1"]
        assigns[:quantity].should == "3"
      end
    end
  end

  describe "handling DELETE /nodes/1" do

    def do_delete
      delete :destroy, :id => "i-12345"
    end

    describe "successful delete" do
      before(:each) do
        @node = mock_model(Node, :destroy => true)
        @node.should_receive(:remove_launched_instance).and_return(true)
        @node.should_receive(:update_attribute).and_return(true)
        Node.stub!(:find_by_instance_id).and_return(@node)
      end

      it "should find the node requested" do
        Node.should_receive(:find_by_instance_id).with("i-12345").and_return(@node)
        do_delete
      end

      it "should redirect to the nodes list" do
        do_delete
        response.should redirect_to(nodes_url)
      end
    end

    describe "failing delete" do
      before(:each) do
        Node.stub!(:find_by_instance_id).and_return(nil)
      end

      it "should redirect to the index for an invalid node" do
        do_delete
        response.should redirect_to(nodes_url)
      end
    end

  end
end
