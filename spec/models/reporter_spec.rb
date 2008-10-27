require File.dirname(__FILE__) + '/../spec_helper'

describe Reporter do

  before(:each) do
    @reporter = create_reporter
  end

  def process_head_message(message)
      report = build_report(message)
      message_type = report[:type]
      case message_type
        when DOWNLOAD
          set_job_download_link(report, message)
        when JOBUNPACKING
          job_status(report, message, "Unpacking")
        when JOBUNPACKED
          job_status(report, message, "Processing")
        when START
          update_chunk(report, message)
        when FINISH
          update_chunk(report, message)
          check_job_status(report)
      end
  end

  describe "process head message" do
    before(:each) do
      @report = mock("report")
      @reporter.should_receive(:build_report).with("message").and_return(@report)
    end

    after(:each) do
      @reporter.process_head_message("message")
    end

    describe "download message" do
      it "should set the job download link" do
        @report.should_receive(:[]).with(:type).and_return(DOWNLOAD)
        @reporter.should_receive(:set_job_download_link).with(@report, "message").and_return(true)
      end
    end

    describe "unpacking message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBUNPACKING)
        @reporter.should_receive(:job_status).with(@report, "message", "Unpacking").and_return(true)
      end
    end

    describe "unpacked message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBUNPACKED)
        @reporter.should_receive(:job_status).with(@report, "message", "Processing").and_return(true)
      end
    end

    describe "start message" do
      it "should update the chunk" do
        @report.should_receive(:[]).with(:type).and_return(START)
        @reporter.should_receive(:update_chunk).with(@report, "message").and_return(true)
      end
    end

    describe "finish message" do
      it "should update the chunk and check the status" do
        @report.should_receive(:[]).with(:type).and_return(FINISH)
        @reporter.should_receive(:update_chunk).with(@report, "message").and_return(true)
        @reporter.should_receive(:check_job_status).with(@report).and_return(true)
      end
    end
  end

  describe "process loop" do
    describe "with created message" do
      it "should complete the steps" do
        @reporter.should_receive(:fetch_created_message).and_return("message")
        @reporter.should_receive(:process_created_message).with("message").and_return(true)
        @reporter.process_loop(false)
      end
    end
    describe "with head message" do
      it "should complete the steps" do
        @reporter.should_receive(:fetch_created_message).and_return(nil)
        @reporter.should_receive(:fetch_head_message).and_return("headmessage")
        @reporter.should_receive(:process_head_message).with("headmessage").and_return(true)
        @reporter.process_loop(false)
      end
    end
    describe "with no message" do
      it "should complete the steps" do
        @reporter.should_receive(:fetch_created_message).and_return(nil)
        @reporter.should_receive(:fetch_head_message).and_return(nil)
        @reporter.should_receive(:sleep).with(30).and_return(true)
        @reporter.process_loop(false)
      end
    end
  end
  
  describe "process created message" do
    it "should update the chunk for the message" do
      message = mock("message")
      report = mock("report")
      @reporter.should_receive(:build_report).with(message).and_return(report)
      @reporter.should_receive(:update_chunk).with(report, message, true).and_return(true)
      @reporter.process_created_message(message)
    end
  end

  describe "run" do
    before(:each) do
      @node = mock_model(Node)
      Aws.should_receive(:instance_type).and_return("type")
      Aws.should_receive(:instance_id).and_return("id")
    end

    it "should complete the steps with a new node" do
      @node.should_receive(:save).and_return(true)
      Node.should_receive(:new).with(:instance_type => "type", :instance_id => "id").and_return(@node)
      @reporter.should_receive(:write_pid).and_return(true)
      @reporter.should_receive(:process_loop).and_return(true)
      @reporter.run
    end

    it "should complete the steps with an existing node" do
      @node.should_receive(:save).and_return(false)
      Node.should_receive(:new).with(:instance_type => "type", :instance_id => "id").and_return(@node)
      @reporter.should_receive(:write_pid).and_return(true)
      @reporter.should_receive(:process_loop).and_return(true)
      @reporter.run
    end
  end

  describe "fetch created message" do
    it "should get a message from the created queue" do
      @message = mock("message", :body => "body")
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(@message)
      Aws.should_receive(:created_chunk_queue).and_return(@queue)
      message = @reporter.fetch_created_message
      message.body.should == "body"
    end

    it "should return nil if the message doesn't exist" do
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(nil)
      Aws.should_receive(:created_chunk_queue).and_return(@queue)
      message = @reporter.fetch_created_message
      message.should be_nil
    end

    it "should delete the message if the body is blank and return nil" do
      @message = mock("message", :body => "")
      @message.should_receive(:delete).and_return(true)
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(@message)
      Aws.should_receive(:created_chunk_queue).and_return(@queue)
      message = @reporter.fetch_created_message
      message.should be_nil
    end
  end

  describe "fetch head message" do
    it "should get a message from the created queue" do
      @message = mock("message", :body => "body")
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(@message)
      Aws.should_receive(:head_queue).and_return(@queue)
      message = @reporter.fetch_head_message
      message.body.should == "body"
    end

    it "should return nil if the message doesn't exist" do
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(nil)
      Aws.should_receive(:head_queue).and_return(@queue)
      message = @reporter.fetch_head_message
      message.should be_nil
    end

    it "should delete the message if the body is blank and return nil" do
      @message = mock("message", :body => "")
      @message.should_receive(:delete).and_return(true)
      @queue = mock("queue")
      @queue.should_receive(:receive).with(60).and_return(@message)
      Aws.should_receive(:head_queue).and_return(@queue)
      message = @reporter.fetch_head_message
      message.should be_nil
    end
  end

  describe "build report" do
    it "should return a hash parsed by YAML" do
      message = mock("message")
      message.should_receive(:body).and_return("--- :thing:thing")
      YAML.should_receive(:load).with("--- :thing:thing").and_return({:thing => "thing"})
      @reporter.build_report(message).should == {:thing => "thing"}
    end
  end

  describe "logger" do
    before(:each) do
      File.should_receive(:join).and_return("reporter.log")
      Logger.should_receive(:new).with("reporter.log").and_return("logger")
    end

    it "should open a new log file and return a new logger" do
      @reporter.logger.should == "logger"
    end
  end

  describe "write pid" do
    it "should write the current process id to a file" do
      File.should_receive(:join).and_return("reporter.pid")
      file = mock("file")
      file.should_receive(:puts).with($$).and_return(true)
      File.should_receive(:open).with("reporter.pid", "w").and_yield(file)
      @reporter.write_pid
    end
  end

  describe "load job" do
    it "should load a job with the id" do
      @job = mock_model(Job)
      Job.stub!(:find).and_return(@job)
      job = @reporter.load_job("id")
      job.should == @job
    end

    it "should log an exception if the job doesn't exist" do
      @logger = mock_model(Logger)
      @logger.should_receive(:error).exactly(3).times.and_return(true)
      @reporter.stub!(:logger).and_return(@logger)
      Job.stub!(:find).and_raise(Exception)
      job = @reporter.load_job("id")
    end
  end
  
  describe "check job status" do
    before(:each) do
      @report = mock("report")
      @report.should_receive(:[]).with(:job_id).and_return(1234)
      @job = mock_model(Job)
      Time.stub!(:now).and_return(1)
    end
    describe "processed and not complete" do
      it "should update the job status and send a pack request" do
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @job.should_receive(:processed?).and_return(true)
        @job.should_receive(:complete?).and_return(false)
        @job.should_receive(:status=).with("Complete").and_return(true)
        @job.should_receive(:finished_at=).with(1.0).and_return(true)
        @job.should_receive(:save).and_return(true)
        @job.should_receive(:send_pack_request).and_return(true)
        @reporter.check_job_status(@report)
      end
    end
    describe "don't send message if not processed" do
      it "should not be processed" do
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @job.should_receive(:processed?).and_return(false)
        @job.should_not_receive(:send_pack_request).and_return(true)
        @reporter.check_job_status(@report)
      end
    end

    describe "don't send message if already complete" do
      it "should not be complete" do
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @job.should_receive(:processed?).and_return(true)
        @job.should_receive(:complete?).and_return(true)
        @job.should_not_receive(:send_pack_request).and_return(true)
        @reporter.check_job_status(@report)
      end
    end
  end

  describe "set job download link" do
    before(:each) do
      @report = mock("report")
      @report.should_receive(:[]).with(:job_id).and_return(1234)
      @message = mock("message")
      @job = mock_model(Job)
    end
    describe "success" do
      it "should have a valid job link" do
        @reporter.should_receive(:create_job_link).and_return("job_link")
        @job.should_receive(:link=).with("job_link").and_return(true)
        @job.should_receive(:save).and_return(true)
        @job.should_receive(:remove_s3_working_folder).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @reporter.set_job_download_link(@report, @message)
      end
    end
  end

  describe "create job link" do
    it "should return a string with the s3 link" do
      report = mock("report")
      report.should_receive(:[]).with(:bucket_name).and_return("bucket_name")
      job = mock_model(Job)
      job.should_receive(:output_file).and_return("outputfile")
      @reporter.create_job_link(report, job).should == "http://s3.amazonaws.com/bucket_name/completed-jobs/outputfile"
    end
  end

  describe "update chunk" do
    before(:each) do
      @chunk = mock_model(Chunk)
      @message = mock("message")
      Chunk.should_receive(:reporter_chunk).with("report").and_return(@chunk)
    end

    describe "success for create" do
      it "should create a chunk and send the process message" do
        @chunk.should_receive(:save).and_return(true)
        @chunk.should_receive(:send_process_message).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.update_chunk("report", @message, true)
      end
    end

    describe "success for update" do
      it "should update a chunk" do
        @chunk.should_receive(:save).and_return(true)
        @chunk.should_not_receive(:send_process_message).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.update_chunk("report", @message)
      end
    end
  end

  describe "job status" do
    before(:each) do
      @job = mock_model(Job)
      @job.should_receive(:status=).and_return(true)
      @message = mock("message")
      @report = mock("report")
      @report.should_receive(:[]).with(:job_id).and_return(1234)
      @reporter.should_receive(:load_job).with(1234).and_return(@job)
    end
    describe "success" do
      it "should update the status of the job" do
        @job.should_receive(:save).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.job_status(@report, @message, "status")
      end
    end
  end

  protected
    def create_reporter
      record = Reporter.new
      record
    end

end
