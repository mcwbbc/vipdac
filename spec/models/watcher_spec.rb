require File.dirname(__FILE__) + '/../spec_helper'

describe Watcher do
  before(:each) do
    @watcher = create_watcher
  end

  describe "fetch message" do
    it "should get a message from the queue" do
      @message = mock("message", :body => "body")
      @queue = mock("queue")
      @queue.should_receive(:receive).with(600).and_return(@message)
      Aws.should_receive(:node_queue).and_return(@queue)
      message = @watcher.fetch_message
      message.body.should == "body"
    end

    it "should return nil if the message doesn't exist" do
      @queue = mock("queue")
      @queue.should_receive(:receive).with(600).and_return(nil)
      Aws.should_receive(:node_queue).and_return(@queue)
      message = @watcher.fetch_message
      message.should be_nil
    end

    it "should delete the message if the body is blank and return nil" do
      @message = mock("message", :body => "")
      @message.should_receive(:delete).and_return(true)
      @queue = mock("queue")
      @queue.should_receive(:receive).with(600).and_return(@message)
      Aws.should_receive(:node_queue).and_return(@queue)
      message = @watcher.fetch_message
      message.should be_nil
    end
  end

  describe "convert message to hash" do
    it "should return a hash for the yaml encoded message" do
      message = mock("message", :body => "key:text")
      YAML.should_receive(:load).with("key:text").and_return({:key => "text"})
      @watcher.convert_message_to_hash(message).should == {:key => "text"}
    end
  end

  describe "create worker" do
    it "should create a worker with the message" do
      worker = mock_model(Worker)
      hash = {:message => "text"}
      Worker.should_receive(:new).with(hash).and_return(worker)
      @watcher.create_worker(hash).should == worker
    end
  end

  describe "process" do
    before(:each) do
      @worker = mock_model(Worker)
      @message = mock("message")
    end

    it "should delete the message if the worker is successful" do
      @message.should_receive(:delete).and_return(true)
      @worker.should_receive(:run).and_return(true)
      @watcher.process(@worker, @message)
    end

    it "should delete the message if an exception occurs" do
      @worker.should_receive(:run).and_raise(RightAws::AwsError)
      @message.should_receive(:delete).and_return(true)
      @watcher.process(@worker, @message)
    end
  end

  describe "run" do
    it "should complete the steps" do
      @watcher.should_receive(:check_queue).and_return(true)
      @watcher.run(false)
    end
  end

  describe "check queue" do
    it "should process the message if we have one" do
      @watcher.should_receive(:fetch_message).and_return("message")
      @watcher.should_receive(:convert_message_to_hash).with("message").and_return("hash")
      @watcher.should_receive(:create_worker).and_return("worker")
      @watcher.should_receive(:process).with("worker", "message").and_return(true)
      @watcher.check_queue
    end
    it "should sleep if there is no message" do
      @watcher.should_receive(:fetch_message).and_return(nil)
      @watcher.should_receive(:sleep).with(15).and_return(true)
      @watcher.check_queue
    end
  end

  protected
    def create_watcher
      record = Watcher.new
      record
    end

end
