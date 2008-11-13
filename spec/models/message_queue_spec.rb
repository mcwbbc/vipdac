require File.dirname(__FILE__) + '/../spec_helper'

describe MessageQueue do

  describe "get" do
    it "should require a queue name" do
       lambda { MessageQueue.get() }.should raise_error(ArgumentError)
    end

    it "should get a message from the queue" do
      AwsMessageQueue.should_receive(:get_message).with('name', 600).and_return("message")
      MessageQueue.get(:name => 'name', :timeout => 600).should == "message"
    end
  end

  describe "put" do
    it "should require a queue name" do
      lambda { MessageQueue.put() }.should raise_error(ArgumentError)
    end

    it "should put a message on the queue" do
      AwsMessageQueue.should_receive(:send_message).with('name', 'message').and_return(true)
      MessageQueue.put(:name => 'name', :message => 'message', :priority => 10).should be_true
    end
  end

end


