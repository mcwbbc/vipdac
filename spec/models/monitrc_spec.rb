require File.dirname(__FILE__) + '/../spec_helper'

describe Monitrc do

  describe "run" do
    before(:each) do
      @logger = mock_model(Logger)
      @logger.should_receive(:debug).with("Creating monitrc files for 2 workers").and_return(true)
      Monitrc.should_receive(:logger).and_return(@logger)
      Monitrc.should_receive(:workers).and_return(2)
      Monitrc.should_receive(:write_node_file).and_return(true)
    end

    describe "as a worker" do
      it "should complete the steps" do
        Monitrc.should_receive(:master?).exactly(2).times.and_return(false)
        Monitrc.should_not_receive(:symlink_reporter)
        Monitrc.should_not_receive(:symlink_beanstalkd)
        Monitrc.run
      end
    end

    describe "as a master" do
      it "should complete the steps" do
        Monitrc.should_receive(:master?).exactly(2).times.and_return(true)
        Monitrc.should_receive(:symlink_reporter).and_return(true)
        Monitrc.should_receive(:symlink_beanstalkd).and_return(true)
        Monitrc.run
      end
    end
  end

  describe "configuration" do
    describe "with an empty hash" do
      it "should return the config hash" do
        AwsParameters.should_receive(:run).and_return({})
        Monitrc.configuration.should == {}
      end
    end
    describe "with an valid hash" do
      it "should return the config hash" do
        @hash = {'workers' => "5"}
        AwsParameters.should_receive(:run).and_return(@hash)
        Monitrc.configuration.should == {'workers' => "5"}
      end
    end
  end

  describe "workers" do
    describe "with an empty hash" do
      it "should return the number of workers" do
        Monitrc.should_receive(:configuration).and_return({})
        Monitrc.workers.should == 1
      end
    end
    describe "with a valid hash" do
      it "should return the number of workers" do
        Monitrc.should_receive(:configuration).twice.and_return({'workers' => "5"})
        Monitrc.workers.should == 5
      end
    end
  end

  describe "master?" do
    it "should return true if no role is specified" do
      Monitrc.should_receive(:configuration).and_return({})
      Monitrc.master?.should be_true
    end
    it "should return false if a role is specified" do
      Monitrc.should_receive(:configuration).and_return({'role' => 'worker'})
      Monitrc.master?.should be_false
    end
  end

  describe "create logger" do
    it "should return logger" do
      @logger = mock_model(Logger)
      Logger.should_receive(:new).with("/pipeline/pipeline.log").and_return(@logger)
      Monitrc.logger.should == @logger
    end
  end

  describe "node template" do
    it "should load the template file" do
      File.should_receive(:read).with("/pipeline/vipdac/config/node.monitrc.template").and_return("template")
      Monitrc.node_template.should == "template"
    end
  end

  describe "assemble node text" do
    it "should create information for each worker" do
      Monitrc.should_receive(:node_template).exactly(3).times.and_return("template-ID ")
      Monitrc.should_receive(:workers).and_return(3)
      Monitrc.assemble_node_text.should eql("template-1 template-2 template-3 \n")
    end
  end

  describe "write node file" do
    it "should write the text to a file" do
      @file = mock("file")
      @file.should_receive(:puts).with("text").and_return(true)
      Monitrc.should_receive(:assemble_node_text).and_return("text")
      File.should_receive(:open).with("/pipeline/vipdac/config/node.monitrc", 514).and_yield(@file)
      Monitrc.write_node_file
    end
  end

  describe "symlink reporter" do
    it "should set the symlinks for the reporter" do
      File.should_receive(:symlink).with("/pipeline/vipdac/config/reporter.monitrc", "/etc/monit/reporter.monitrc").and_return(true)
      File.should_receive(:symlink).with("/pipeline/vipdac/config/init-d-reporter", "/etc/init.d/reporter").and_return(true)
      Monitrc.symlink_reporter
    end
  end

  describe "symlink beanstalkd" do
    it "should set the symlinks for the beanstalkd" do
      File.should_receive(:symlink).with("/pipeline/vipdac/config/beanstalkd.monitrc", "/etc/monit/beanstalkd.monitrc").and_return(true)
      File.should_receive(:symlink).with("/pipeline/vipdac/config/init-d-beanstalkd", "/etc/init.d/beanstalkd").and_return(true)
      Monitrc.symlink_beanstalkd
    end
  end

  describe "symlink thin" do
    it "should set the symlinks for thin" do
      File.should_receive(:symlink).with("/pipeline/vipdac/config/thin.monitrc", "/etc/monit/thin.monitrc").and_return(true)
      Monitrc.symlink_thin
    end
  end

end
