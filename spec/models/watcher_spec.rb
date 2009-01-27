require File.dirname(__FILE__) + '/../spec_helper'

describe Watcher do
  before(:each) do
    @watcher = create_watcher
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

  end

  describe "run" do
    it "should complete the steps" do
      @watcher.should_receive(:check_queue).and_return(true)
      @watcher.run(false)
    end
  end

  describe "logger" do
    it "should return a logger" do
      logger = mock("logger")
      Logger.should_receive(:new).with("/pipeline/pipeline.log").and_return(logger)
      @watcher.logger.should == logger
    end
  end

  describe "check queue" do
    it "should process the message if we have one" do
      MessageQueue.should_receive(:get).with(:name => 'node', :peek => false).and_return("message")
      @watcher.should_receive(:convert_message_to_hash).with("message").and_return("hash")
      @watcher.should_receive(:create_worker).and_return("worker")
      @watcher.should_receive(:process).with("worker", "message").and_return(true)
      @watcher.check_queue
    end
  
    describe "with an exception" do
      it "should delete the message if it's NoSuchKey" do
        MessageQueue.should_receive(:get).with(:name => 'node', :peek => false).and_return("message")
        @watcher.should_receive(:convert_message_to_hash).with("message").and_return("hash")
        @watcher.should_receive(:create_worker).and_return("worker")
        @watcher.should_receive(:process).with("worker", "message").and_raise(Exception.new)
        HoptoadNotifier.should_receive(:notify).with({:request=>{:params=>{:message=>"message"}}, :error_message=>"Exception: Exception", :error_class=>"Exception"}).and_return(true)
        @watcher.check_queue
      end

      it "should exit on SignalException errors" do
        MessageQueue.should_receive(:get).with(:name => 'node', :peek => false).and_raise(SignalException.new("TERM"))
        HoptoadNotifier.should_not_receive(:notify)
        @watcher.should_receive(:exit).and_return(true)
        @watcher.check_queue
      end

      it "should exit on Interrupt errors" do
        MessageQueue.should_receive(:get).with(:name => 'node', :peek => false).and_raise(Interrupt.new("EXIT"))
        HoptoadNotifier.should_not_receive(:notify)
        @watcher.should_receive(:exit).and_return(true)
        @watcher.check_queue
      end
    end
  end

  protected
    def create_watcher
      record = Watcher.new
      record
    end

end
