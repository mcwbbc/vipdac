require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Node do
  before(:each) do
    @node = Node.new(:instance_type => 'm1.small')
    @ec2_mock = mock("ec2")
    @ec2_mock.stub!(:describe_instances).and_return([{:name => 'a', :aws_state => 'running'},{:name => 'b', :aws_state => 'running'},{:name => 'c', :aws_state => 'terminated'}])
    @ec2_mock.stub!(:launch_instances).and_return([:aws_instance_id => 'ec2-instance'])
    @ec2_mock.stub!(:terminate_instances).and_return(true)

    Aws.stub!(:ec2).and_return(@ec2_mock)
    Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret'})
    Aws.stub!(:amis).and_return({'x86_64' => 'bigone', 'i386' => 'smallone'})
    Aws.stub!(:workers).with('m1.small').and_return(1)
    Aws.stub!(:workers).with('c1.medium').and_return(4)
    
    Chunk.stub!(:find).and_return([{:chunk_id => 1},{:chunk_id => 2}])

  end

  describe "instance id" do
    it "should be unique" do
      @node = Node.new(:instance_type => 'm1.small', :instance_id => "id")
      @node.should be_valid
      @node.save
      @n = Node.new(:instance_type => 'm1.small', :instance_id => "id")
      @n.should_not be_valid
    end
  end

  describe "requesting a description" do
    it "should load a node description from aws" do
      @ec2_mock.should_receive(:describe_instances).with(['b']).and_return(['b'])
      @node.instance_id = 'b'
      @node.describe.should eql('b')
    end
  end

  describe "creating a new node" do

    it "should have an instance type" do
      @node.instance_type.should eql('m1.small')
    end

    it "should be valid" do
      @node.should be_valid
    end
  end

  describe "requesting an ami_type" do
    it "should return i386 for m1.small" do
      @node.ami_type.should eql('i386')
    end

    it "should return i386 for c1.medium" do
      @node.instance_type = "c1.medium"
      @node.ami_type.should eql('i386')
    end

    it "should return x86_64 for everything else" do
      @node.instance_type = "cheese"
      @node.ami_type.should eql('x86_64')
    end
  end

  describe "listing" do
    it "should return an array of 3" do
      Node.listing.size.should eql(3)
    end

    it "should have an instance named 'a'" do
      Node.listing.include?({:name => 'a', :aws_state => 'running'}).should be_true
    end
  end

  describe "active_nodes" do
    it "should return an array of 2" do
      Node.active_nodes.size.should eql(2)
    end

    it "should not have an instance named 'c'" do
      Node.active_nodes.include?({:name => 'c', :aws_state => 'terminated'}).should_not be_true
    end
  end

  describe "requesting user_data" do
    it "should return a string with the user data with 1 worker for a small instance" do
      @node.user_data.should eql("aws_access=access,aws_secret=secret,workers=1,role=worker")
    end

    it "should return a string with the user data with 4 worker for a meduim instance" do
      @node.instance_type = "c1.medium"
      @node.user_data.should eql("aws_access=access,aws_secret=secret,workers=4,role=worker")
    end
  end

  describe "launching" do
    it "should create an instance with name 'ec2-instance'" do
      @node.launch
      @node.instance_id.should eql("ec2-instance")
    end

  end

  describe "remove instances" do
    it "should be nil for unknown instance" do
      @ec2_mock.should_receive(:describe_instances).with(['x']).and_return([])
      @node.instance_id = 'x'
      @node.remove_launched_instance.should be_nil
    end

    it "should be true for a valid instance" do
      @node.remove_launched_instance.should be_true
    end
  end

  describe "chunks" do
    it "should have 1 chunk" do
      @node.chunks.size.should eql(2)
    end
  end

end
