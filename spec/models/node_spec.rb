require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Node do
  describe "with mocks" do
    before(:each) do
      @node = Node.new(:instance_type => 'm1.small')
      @ec2_mock = mock("ec2")
      @ec2_mock.stub!(:describe_instances).and_return([{:name => 'a', :aws_instance_id => 'i1', :aws_state => 'running'},{:name => 'b', :aws_instance_id => 'i2', :aws_state => 'running'},{:name => 'c', :aws_instance_id => 'i3', :aws_state => 'terminated'}])
      @ec2_mock.stub!(:launch_instances).and_return([:aws_instance_id => 'ec2-instance'])
      @ec2_mock.stub!(:terminate_instances).and_return(true)

      Aws.stub!(:ec2).and_return(@ec2_mock)
      Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret', 'local-ipv4' => '100.100.100.100'})
      Aws.stub!(:amis).and_return({'x86_64' => 'bigone', 'i386' => 'smallone'})
      Aws.stub!(:workers).with('m1.small').and_return(1)
      Aws.stub!(:workers).with('c1.medium').and_return(4)
    end

    describe "size of node" do
      it "should return the text string for the node size" do
        Node.should_receive(:find).with(:first, {:conditions=>["instance_id LIKE ?", "id%"], :select=>"instance_type"}).and_return("c1.medium")
        Node.size_of_node("id").should == "c1.medium"
      end
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

      it "should return an hash of invalid on error" do
        @ec2_mock.should_receive(:describe_instances).with(['b']).and_raise(RightAws::AwsError)
        @node.instance_id = 'b'
        @node.describe.should == {:aws_state => "INVALID", :aws_reason => "INVALID", :aws_image_id => "INVALID", :dns_name => "INVALID", :aws_launch_time => "INVALID"}
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
        Node.listing.include?({:name => 'a', :aws_instance_id => 'i1', :aws_state => 'running'}).should be_true
      end
    end

    describe "launchable nodes" do
      it "should return an array of 1 to 20" do
        Node.launchable_nodes.should == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"]
      end
    end

    describe "status hash" do
      it "should return a hash with the instance_id as the key, and the status as the value" do
        Node.status_hash.should == {"i1"=>"running", "i2"=>"running", "i3"=>"terminated"}
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
      describe "without folder name" do
        it "should return a string with the user data with 1 worker for a small instance" do
          @node.user_data.should eql("aws_access=access,aws_secret=secret,workers=1,role=worker,beanstalkd=100.100.100.100")
        end

        it "should return a string with the user data with 4 worker for a meduim instance" do
          @node.instance_type = "c1.medium"
          @node.user_data.should eql("aws_access=access,aws_secret=secret,workers=4,role=worker,beanstalkd=100.100.100.100")
        end
      end

      describe "with folder name" do
        it "should return a string with the user data with 4 worker for a meduim instance" do
          Aws.should_receive(:folder).twice.and_return("user_folder")
          @node.instance_type = "c1.medium"
          @node.user_data.should eql("aws_access=access,aws_secret=secret,workers=4,role=worker,beanstalkd=100.100.100.100,folder=user_folder")
        end
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
      it "should have 2 chunks" do
        @node = Node.new(:instance_type => 'm1.small', :instance_id => "id")
        Chunk.should_receive(:find_for_node).with("id", 10).and_return([{:chunk_id => 1},{:chunk_id => 2}])
        @node.chunks.size.should eql(2)
      end
    end
  end

  describe "launch" do
    it "should create an instance with name 'ec2-instance'" do
      @node = Node.new(:instance_type => 'm1.small')
      @node.should_receive(:launch_parameters).and_return({:instance => "instance"})

      @ec2_mock = mock("ec2")
      @ec2_mock.should_receive(:launch_instances).with("ami", {:instance => "instance"}).and_return([:aws_instance_id => 'ec2-instance'])

      Aws.stub!(:ec2).and_return(@ec2_mock)
      Aws.should_receive(:ami_id).and_return("ami")

      @node.launch
      @node.instance_id.should eql("ec2-instance")
    end
  end

  describe "launch parameters" do
    before(:each) do
      @node = Node.new(:instance_type => 'm1.small')
    end

    it "should include the instance type" do
      Aws.stub!(:keypairs).and_return([])
      @node.launch_parameters.key?(:instance_type).should be_true
      @node.launch_parameters[:instance_type].should == "m1.small"
    end

    it "should include the user data" do
      Aws.stub!(:keypairs).and_return([])
      @node.should_receive(:user_data).twice.and_return("userdata")
      @node.launch_parameters.key?(:user_data).should be_true
      @node.launch_parameters[:user_data].should == "userdata"
    end

    it "should include the key name if the keypair exists" do
      Aws.should_receive(:keypairs).twice.and_return([{:aws_fingerprint=> "01:02", :aws_key_name=>"key-1"}])
      Aws.should_receive(:keypair).twice.and_return("key-1")
      @node.launch_parameters.key?(:key_name).should be_true
      @node.launch_parameters[:key_name].should == "key-1"
    end

    it "should not include the key name if the keypair doesn't exist" do
      Aws.stub!(:keypairs).and_return([])
      @node.launch_parameters.key?(:key_name).should be_false
    end
  end

end
