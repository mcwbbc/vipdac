require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Aws do

  describe "keys" do
    it "should return the values from AwsParameters" do
      AwsParameters.should_receive(:run).and_return("keys")
      Aws.keys.should == "keys"
    end
  end

  describe "s3 actions" do
    before(:each) do
      @s3 = mock("s3")
      Aws.stub!(:s3i).and_return(@s3)
      Aws.should_receive(:bucket_name).and_return("bucket")
    end

    it "should put an object on s3" do
      @s3.should_receive(:put).with("bucket", "object","data",{})
      Aws.put_object("object", "data")
    end

    it "should get an object from s3" do
      @s3.should_receive(:get).with("bucket", "object")
      Aws.get_object("object")
    end

    it "should delete a folder from s3" do
      @s3.should_receive(:delete_folder).with("bucket", "object")
      Aws.delete_folder("object")
    end

    it "should delete an object from s3" do
      @s3.should_receive(:delete_folder).with("bucket", "object")
      Aws.delete_object("object")
    end

    it "should create a bucket" do
      @s3.should_receive(:create_bucket).with("bucket").and_return(true)
      Aws.create_bucket.should be_true
    end

  end


  describe "sqs actions" do
    before(:each) do
      @sqs = mock("sqs")
      Aws.stub!(:sqs).and_return(@sqs)
    end

    describe "creating queues" do
      it "should make a head queue" do
        Aws.should_receive(:head_queue_name).and_return("head_queue")
        @sqs.should_receive(:queue).with("head_queue", true).and_return(true)
        Aws.head_queue.should be_true
      end
      it "should make a node queue" do
        Aws.should_receive(:node_queue_name).and_return("node_queue")
        @sqs.should_receive(:queue).with("node_queue", true).and_return(true)
        Aws.node_queue.should be_true
      end
      it "should make a created chunk queue" do
        Aws.should_receive(:created_chunk_queue_name).and_return("chunk_queue")
        @sqs.should_receive(:queue).with("chunk_queue", true).and_return(true)
        Aws.created_chunk_queue.should be_true
      end
    end

    describe "sending messages" do
      before(:each) do
        @queue = mock("queue")
        @queue.should_receive(:send_message).with("hello").and_return(true)
      end
      it "should send a node message" do
        Aws.should_receive(:node_queue).and_return(@queue)
        Aws.send_node_message("hello").should be_true
      end
      it "should send a head message" do
        Aws.should_receive(:head_queue).and_return(@queue)
        Aws.send_head_message("hello").should be_true
      end
      it "should send a node message" do
        Aws.should_receive(:created_chunk_queue).and_return(@queue)
        Aws.send_created_chunk_message("hello").should be_true
      end
    end
  end

  describe "create interfaces" do
    before(:each) do
      Aws.should_receive(:keys).twice.and_return({'aws_access' => 'access', 'aws_secret' => 'secret'})
    end
    it "should create an ec2 interface" do
      RightAws::Ec2.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.ec2.should == "interface"
    end
    it "should create an sqs interface" do
      RightAws::SqsGen2.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.sqs.should == "interface"
    end
    it "should create an s3i interface" do
      RightAws::S3Interface.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.s3i.should == "interface"
    end
  end

  describe "with mocks" do
    before(:each) do
      @sqs = mock("sqs")
      @s3i = mock("s3i")
      @ec2 = mock("ec2")

      Aws.stub!(:ec2).and_return(@ec2)
      Aws.stub!(:sqs).and_return(@sqs)
      Aws.stub!(:s3i).and_return(@s3i)
      Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret', 'public-hostname' => 'hostname', 'instance-id' => 'instance-id', 'instance-type' => 'instance-type'})
    end
    describe "current hostname" do
      it "should be 'test' for test environment" do
        Aws.current_hostname.should == "test"
      end
      it "should be the public hostname key" do
        env = mock("env", :test? => false)
        Rails.should_receive(:env).and_return(env)
        Aws.current_hostname.should == "hostname"
      end
    end

    describe "instance id" do
      it "should be the instance id key" do
        Aws.instance_id.should == "instance-id"
      end
    end

    describe "instance type" do
      it "should be the instance type" do
        Aws.instance_type.should == "instance-type"
      end
    end

    describe "amis" do
      it "should return an ami for i386 with id ami-12345" do
        Aws.stub!(:ami_id).and_return("ami-12345")
        Aws.amis.should == {'i386' => 'ami-12345'}
      end
    end

    describe "workers" do
      it "should return a number of wokers based on the instance type" do
        Aws.workers("m1.small").should == 1
        Aws.workers("c1.medium").should == 4
      end
    end

    describe "bucket" do
      it "should have a name" do
        Aws.bucket_name.should == "access-vipdac"
      end
    end

    describe "head queue" do
      it "should have a name" do
        Aws.head_queue_name.should eql("access-vipdac-head")
      end
    end

    describe "node queue" do
      it "should have a name" do
        Aws.node_queue_name.should eql("access-vipdac-node")
      end
    end

    describe "created chunk queue" do
      it "should have a name" do
        Aws.created_chunk_queue_name.should eql("access-vipdac-created-chunk")
      end
    end
  end

end
