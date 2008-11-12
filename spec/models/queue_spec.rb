require File.dirname(__FILE__) + '/../spec_helper'

describe Queue do

  describe "get" do
    it "should require a queue name" do
       lambda { Queue.get() }.should raise_error(Queue::NoNameError)
    end

    it "should get a message from the queue" do
      Queue.get(:name => 'name', :timeout => 600).should == "message"
    end
  end

  describe "put" do
    it "should require a queue name" do
      lambda { Queue.put() }.should raise_error(Queue::NoNameError)
    end

    it "should put a message on the queue" do
      Queue.put(:message => 'message', :priority => 10).should be_true
    end
  end

  describe "delete" do
    it "should remove a message from the queue" do
      message = mock("message")
      
      Queue.delete(message).should be_true
    end
  end

end
