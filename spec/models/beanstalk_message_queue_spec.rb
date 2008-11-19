require File.dirname(__FILE__) + '/../spec_helper'

describe BeanstalkMessageQueue do

  describe "get message" do
    describe "with peek" do
      it "should return a message if it exists" do
        message = mock("message")
        queue = mock("queue")
        queue.should_receive(:peek_ready).and_return(message)
        queue.should_receive(:reserve).and_return(message)
        BeanstalkMessageQueue.should_receive(:get_queue).twice.with('cheese').and_return(queue)
        BeanstalkMessageQueue.get_message('cheese', true).should == message
      end

      it "should return nil if there was no peek" do
        queue = mock("queue")
        queue.should_receive(:peek_ready).and_return(nil)
        BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
        BeanstalkMessageQueue.get_message('cheese', true).should be_nil
      end
    end

    describe "without peek" do
      describe "with not connected error" do
        it "should sleep for 10 seconds" do
          queue = mock("queue")
          queue.should_receive(:reserve).and_raise(Beanstalk::NotConnected)
          BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
          BeanstalkMessageQueue.should_receive(:sleep).with(10).and_return(false)
          BeanstalkMessageQueue.get_message('cheese')
        end
      end

      it "should return a message if it exists" do
        message = mock("message")
        queue = mock("queue")
        queue.should_receive(:reserve).and_return(message)
        BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
        BeanstalkMessageQueue.get_message('cheese').should == message
      end

      it "should return a message if it exists explicit false peek" do
        message = mock("message")
        queue = mock("queue")
        queue.should_receive(:reserve).and_return(message)
        BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
        BeanstalkMessageQueue.get_message('cheese', false).should == message
      end

      it "should return a message if it exists nil peek" do
        message = mock("message")
        queue = mock("queue")
        queue.should_receive(:reserve).and_return(message)
        BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
        BeanstalkMessageQueue.get_message('cheese', nil).should == message
      end
    end
  end

  describe "send message" do

    describe "with not connected error" do
      it "should sleep for 10 seconds" do
        queue = mock("queue")
        queue.should_receive(:put).with('message', 65536, 0, 600).and_raise(Beanstalk::NotConnected)
        BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
        BeanstalkMessageQueue.should_receive(:sleep).with(10).and_return(false)
        BeanstalkMessageQueue.send_message('cheese', 'message')
      end
    end
    
    it "should send a message with the default parameters" do
      queue = mock("queue")
      queue.should_receive(:put).with('message', 65536, 0, 600)
      BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
      BeanstalkMessageQueue.send_message('cheese', 'message')
    end

    it "should send a message with the given parameters" do
      queue = mock("queue")
      queue.should_receive(:put).with('message', 10, 0, 60)
      BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
      BeanstalkMessageQueue.send_message('cheese', 'message', 10, 0, 60)
    end

    it "should send a message with the nil parameters" do
      queue = mock("queue")
      queue.should_receive(:put).with('message', 65536, 0, 600)
      BeanstalkMessageQueue.should_receive(:get_queue).with('cheese').and_return(queue)
      BeanstalkMessageQueue.send_message('cheese', 'message', nil, 0, nil)
    end
  end

  describe "create queue" do
    it "should create a queue with the specific name" do
      queue = mock("queue")
      BeanstalkMessageQueue.should_receive(:server_ip).and_return("127.0.0.1")
      Beanstalk::Pool.should_receive(:new).with(["127.0.0.1:11300"], 'cheese').and_return(queue)
      BeanstalkMessageQueue.should_receive(:queue_hash).and_return({})
      BeanstalkMessageQueue.create_queue('cheese').should == queue
    end
  end

  describe "get queue" do
    it "should return the queue if it's in the hash" do
      queue = mock("queue")
      BeanstalkMessageQueue.should_receive(:queue_hash).twice.and_return({'cheese' => queue})
      BeanstalkMessageQueue.get_queue('cheese').should == queue
    end

    it "should create the queue if it doesn't exist in the hash" do
      queue = mock("queue")
      BeanstalkMessageQueue.should_receive(:queue_hash).and_return({})
      BeanstalkMessageQueue.should_receive(:create_queue).and_return(queue)
      BeanstalkMessageQueue.get_queue('cheese').should == queue
    end
  end

  describe "queue hash" do
    before(:each) do
      Object.send(:remove_const, 'BeanstalkMessageQueue')
      load 'beanstalk_message_queue.rb'
    end
    
    it "should return an empty hash on first run" do
      BeanstalkMessageQueue.queue_hash.should == {}
    end

    it "should return an hash of queues if they exist" do
      queue = mock("queue")
      BeanstalkMessageQueue.queue_hash['one'] = queue
      BeanstalkMessageQueue.queue_hash.should == {'one' => queue}
    end
  end

  describe "beanstalkd server address" do
    before(:each) do
      Object.send(:remove_const, 'BeanstalkMessageQueue')
      load 'beanstalk_message_queue.rb'
    end
  
    it "should use the local_ipv4 if we're on the head" do
      AwsParameters.should_receive(:run).and_return({'local-ipv4' => '127.0.0.1'})
      3.times { BeanstalkMessageQueue.server_ip.should == '127.0.0.1' }
    end

    it "should use the beanstalkd if we're on a worker" do
      AwsParameters.should_receive(:run).and_return({'local-ipv4' => '127.0.0.1', 'beanstalkd' => '168.0.0.1'})
      3.times { BeanstalkMessageQueue.server_ip.should == '168.0.0.1' }
    end
  end

end
