require File.dirname(__FILE__) + '/../spec_helper'

describe AwsMessageQueue do

  before(:each) do
    Object.send(:remove_const, 'AwsMessageQueue')
    load 'aws_message_queue.rb'
  end

  describe "sqs actions" do
    before(:each) do
      @sqs = mock("sqs")
      Aws.stub!(:sqs).and_return(@sqs)
    end

    describe "creating queues" do
      it "should make a head queue" do
        AwsMessageQueue.should_receive(:head_queue_name).and_return("head_queue")
        @sqs.should_receive(:queue).with("head_queue", true).and_return(true)
        AwsMessageQueue.head_queue.should be_true
      end
      it "should make a node queue" do
        AwsMessageQueue.should_receive(:node_queue_name).and_return("node_queue")
        @sqs.should_receive(:queue).with("node_queue", true).and_return(true)
        AwsMessageQueue.node_queue.should be_true
      end
      it "should make a created chunk queue" do
        AwsMessageQueue.should_receive(:created_chunk_queue_name).and_return("chunk_queue")
        @sqs.should_receive(:queue).with("chunk_queue", true).and_return(true)
        AwsMessageQueue.created_chunk_queue.should be_true
      end
    end

    describe "sending messages" do
      before(:each) do
        @queue = mock("queue")
        @queue.should_receive(:send_message).with("hello").and_return(true)
      end
      it "should send a node message" do
        AwsMessageQueue.should_receive(:node_queue).and_return(@queue)
        AwsMessageQueue.send_message('node', "hello").should be_true
      end
      it "should send a head message" do
        AwsMessageQueue.should_receive(:head_queue).and_return(@queue)
        AwsMessageQueue.send_message('head', "hello").should be_true
      end
      it "should send a created chunk message" do
        AwsMessageQueue.should_receive(:created_chunk_queue).and_return(@queue)
        AwsMessageQueue.send_message('created_chunk', "hello").should be_true
      end
    end
  end

  ["created_chunk", "head", "node"].each do |queue_name|
    describe "get #{queue_name} message" do
      it "should get a message from the queue" do
        message = mock("message")
        message.should_receive(:body).and_return("body")
        queue = mock("queue")
        queue.should_receive(:receive).with(60).and_return(message)
        AwsMessageQueue.should_receive("#{queue_name}_queue".to_sym).and_return(queue)
        AwsMessageQueue.get_message(queue_name, 60).should == message
      end

      it "should return nil if the message doesn't exist" do
        queue = mock("queue")
        queue.should_receive(:receive).with(60).and_return(nil)
        AwsMessageQueue.should_receive("#{queue_name}_queue".to_sym).and_return(queue)
        AwsMessageQueue.get_message(queue_name, 60).should == nil
      end

      it "should delete the message if the body is blank and return nil" do
        message = mock("message")
        message.should_receive(:body).and_return("")
        message.should_receive(:delete).and_return(true)
        queue = mock("queue")
        queue.should_receive(:receive).with(60).and_return(message)
        AwsMessageQueue.should_receive("#{queue_name}_queue".to_sym).and_return(queue)
        AwsMessageQueue.get_message(queue_name, 60).should == nil
      end
    end
  end

  describe "queue names" do
    before(:each) do
      @sqs = mock("sqs")
      Aws.stub!(:sqs).and_return(@sqs)
      Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret', 'public-hostname' => 'hostname',
                                   'instance-id' => 'instance-id', 'instance-type' => 'instance-type',
                                   'local-hostname' => 'local-hostname', 'local-ipv4' => 'local-ipv4', 'public-keys' => '0=ec2-keypair'})
    end

    describe "head queue" do
      it "should have a name" do
        AwsMessageQueue.head_queue_name.should eql("access-vipdac-head")
      end
    end

    describe "node queue" do
      it "should have a name" do
        AwsMessageQueue.node_queue_name.should eql("access-vipdac-node")
      end
    end

    describe "created chunk queue" do
      it "should have a name" do
        AwsMessageQueue.created_chunk_queue_name.should eql("access-vipdac-created-chunk")
      end
    end

  end



end
