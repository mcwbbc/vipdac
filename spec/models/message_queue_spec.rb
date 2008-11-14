require File.dirname(__FILE__) + '/../spec_helper'

describe MessageQueue do

      def put(hash)
  #      AwsMessageQueue.send_message(hash[:name], hash[:message])
        BeanstalkMessageQueue.send_message(hash[:name], hash[:message], hash[:priority], 0, hash[:ttr])
      end


  describe "get" do
    it "should require a queue name" do
       lambda { MessageQueue.get() }.should raise_error(ArgumentError)
    end

    it "should get a message from the queue" do
#      AwsMessageQueue.should_receive(:get_message).with('name', 600).and_return("message")
      BeanstalkMessageQueue.should_receive(:get_message).with('name', true).and_return("message")
      MessageQueue.get(:name => 'name', :peek => true).should == "message"
    end

    it "should get a message from the queue without peek" do
      BeanstalkMessageQueue.should_receive(:get_message).with('name', nil).and_return("message")
      MessageQueue.get(:name => 'name').should == "message"
    end
  end

  describe "put" do
    it "should require a queue name" do
      lambda { MessageQueue.put() }.should raise_error(ArgumentError)
    end

    it "should put a message on the queue" do
#      AwsMessageQueue.should_receive(:send_message).with('name', 'message').and_return(true)
      BeanstalkMessageQueue.should_receive(:send_message).with('name', 'message', 10, 0, 600).and_return(true)
      MessageQueue.put(:name => 'name', :message => 'message', :priority => 10, :ttr => 600).should be_true
    end

    it "should put a message on the queue with the defaults" do
      BeanstalkMessageQueue.should_receive(:send_message).with('name', 'message', nil, 0, nil).and_return(true)
      MessageQueue.put(:name => 'name', :message => 'message').should be_true
    end
  end

end


