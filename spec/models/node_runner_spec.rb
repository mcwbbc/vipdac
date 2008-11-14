require File.dirname(__FILE__) + '/../spec_helper'

describe NodeRunner do

  describe "run" do
    before(:each) do
      @logger = mock_model(Logger)
      NodeRunner.should_receive(:setup_logger).and_return(@logger)
      NodeRunner.should_receive(:check_configuration).and_return(true)
      NodeRunner.should_receive(:setup_bucket).and_return(true)
      NodeRunner.should_receive(:launch_watcher).and_return(true)
    end

    it "should launch a watcher with node id 1" do
      @logger.should_receive(:debug).with("Launching node-1 with pid #{$$}").and_return(true)
      NodeRunner.should_receive(:write_pid_file).with(1).and_return(true)
      NodeRunner.run([])
    end

    it "should launch a watcher with node id 1234" do
      @logger.should_receive(:debug).with("Launching node-1234 with pid #{$$}").and_return(true)
      NodeRunner.should_receive(:write_pid_file).with(1234).and_return(true)
      NodeRunner.run([1234])
    end

  end

  describe "check configuration" do

    it "should pass if all parameters exist" do
      @config = {'aws_access' => "access", 'aws_secret' => "secret", 'instance-id' => "instance"}
      AwsParameters.should_receive(:run).and_return(@config)
      NodeRunner.check_configuration.should be_true
    end

    it "should require a aws_access key" do
      @config = {'aws_secret' => "secret", 'instance-id' => "instance"}
      AwsParameters.should_receive(:run).and_return(@config)
      lambda { NodeRunner.check_configuration }.should raise_error("Instance must be launched with aws_access, aws_secret and instance_id parameters, but got: aws_secretsecretinstance-idinstance")
    end

    it "should require a aws_secret key" do
      @config = {'aws_access' => "access", 'instance-id' => "instance"}
      AwsParameters.should_receive(:run).and_return(@config)
      lambda { NodeRunner.check_configuration }.should raise_error("Instance must be launched with aws_access, aws_secret and instance_id parameters, but got: instance-idinstanceaws_accessaccess")
    end

    it "should require an instance-id" do
      @config = {'aws_secret' => "secret", 'aws_access' => "access"}
      AwsParameters.should_receive(:run).and_return(@config)
      lambda { NodeRunner.check_configuration }.should raise_error("Instance must be launched with aws_access, aws_secret and instance_id parameters, but got: aws_secretsecretaws_accessaccess")
    end
  end

  describe "setup logger" do
    it "should create a new logger" do
      @logger = mock_model(Logger)
      Logger.should_receive(:new).with("/pipeline/pipeline.log").and_return(@logger)
      NodeRunner.setup_logger.should == @logger
    end
  end
  
  describe "launch watcher" do
    it "should create and launch the watcher" do
      @watcher = mock_model(Watcher)
      @watcher.should_receive(:run).and_return(true)
      Watcher.should_receive(:new).and_return(@watcher)
      NodeRunner.launch_watcher
    end
  end

  describe "pid filename" do
    it "should return the filename for the pid file" do
      NodeRunner.pid_filename(1234).should eql("/pipeline/node-1234.pid")
    end
  end

  describe "write_pid_file" do
    it "should write the pid to a file" do
      @file = mock("file")
      @file.should_receive(:puts).with($$).and_return(true)
      File.should_receive(:open).with("/pipeline/node-1234.pid", "w").and_yield(@file)
      NodeRunner.write_pid_file(1234)
    end
  end

  describe "setup bucket" do
    it "should create a bucket for use" do
      @bucket = mock("bucket")
      Aws.should_receive(:create_bucket).and_return(@bucket)
      NodeRunner.setup_bucket
    end
  end

end
