require File.dirname(__FILE__) + '/../spec_helper'

describe Reporter do

  before(:each) do
    @reporter = create_reporter
  end

  describe "check for stuck jobs" do
    it "should find all incomplete jobs" do
      Job.should_receive(:incomplete).and_return([])
      @reporter.check_for_stuck_jobs
    end

    describe "given an incomplete job" do
      describe "with stuck chunks" do
        it "should send process messages for all non finished chunks" do
          j1 = mock_model(Job)
          j1.should_receive(:stuck_chunks?).and_return(true)
          j1.should_receive(:priority=).with(50).and_return(true)
          j1.should_receive(:save!).and_return(true)
          j1.should_receive(:resend_stuck_chunks).and_return(true)
          j2 = mock_model(Job)
          j2.should_receive(:stuck_chunks?).and_return(false)
          j2.should_receive(:stuck_packing?).and_return(false)
          jobs = [j1, j2]
          Job.should_receive(:incomplete).and_return(jobs)
          @reporter.check_for_stuck_jobs
        end
      end
      describe "with stuck packing" do
        it "should send process messages for all non finished chunks" do
          j1 = mock_model(Job)
          j1.should_receive(:stuck_chunks?).and_return(false)
          j1.should_receive(:stuck_packing?).and_return(false)
          j2 = mock_model(Job)
          j2.should_receive(:stuck_chunks?).and_return(false)
          j2.should_receive(:stuck_packing?).and_return(true)
          j2.should_receive(:send_pack_request)
          jobs = [j1, j2]
          Job.should_receive(:incomplete).and_return(jobs)
          @reporter.check_for_stuck_jobs
        end
      end
    end
  end

  describe "process head message" do
    before(:each) do
      @report = mock("report")
      @message = mock("message")
      @reporter.should_receive(:build_report).with(@message).and_return(@report)
    end

    after(:each) do
      @reporter.process_head_message(@message)
    end

    describe "unknown message" do
      it "should update the chunk and check the status" do
        @report.should_receive(:[]).with(:type).and_return("cheese")
        @message.should_receive(:delete).and_return(true)
      end
    end

    describe "created message" do
      it "should set the job download link" do
        @report.should_receive(:[]).with(:type).and_return(CREATED)
        @reporter.should_receive(:update_chunk).with(@report, @message, true).and_return(true)
      end
    end

    describe "unpacking message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBUNPACKING)
        @reporter.should_receive(:job_status).with(@report, @message, "Unpacking").and_return(true)
      end
    end

    describe "unpacked message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBUNPACKED)
        @reporter.should_receive(:job_status).with(@report, @message, "Processing").and_return(true)
      end
    end

    describe "packing message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBPACKING)
        @reporter.should_receive(:job_status).with(@report, @message, "Packing").and_return(true)
      end
    end

    describe "packed message" do
      it "should set the job status" do
        @report.should_receive(:[]).with(:type).and_return(JOBPACKED)
        @reporter.should_receive(:set_job_download_link).with(@report, @message).and_return(true)
      end
    end

    describe "start message" do
      it "should update the chunk" do
        @report.should_receive(:[]).with(:type).and_return(START)
        @reporter.should_receive(:update_chunk).with(@report, @message).and_return(true)
      end
    end

    describe "finish message" do
      it "should update the chunk and check the status" do
        @report.should_receive(:[]).with(:type).and_return(FINISH)
        @reporter.should_receive(:update_chunk).with(@report, @message).and_return(true)
        @reporter.should_receive(:check_job_status).with(@report).and_return(true)
      end
    end
  end

  describe "process loop" do
    describe "with head message" do
      describe "with exceptions" do
        it "should fail getting the message" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_raise(Exception)
          HoptoadNotifier.should_receive(:notify).with({:error_message=>"Exception: Exception", :request=>{:params=>nil}, :error_class=>"Exception"}).and_return(true)
          @reporter.process_loop(false)
        end

        it "should fail processing the message" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return("headmessage")
          @reporter.should_receive(:process_head_message).with("headmessage").and_raise(Exception)
          HoptoadNotifier.should_receive(:notify).with({:error_message=>"Exception: Exception", :request=>{:params=>"headmessage"}, :error_class=>"Exception"}).and_return(true)
          @reporter.process_loop(false)
        end

        it "should fail checking for chunks" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return("headmessage")
          @reporter.should_receive(:process_head_message).with("headmessage").and_return(true)
          @reporter.should_receive(:minute_ago?).and_return(true)
          @reporter.should_receive(:check_for_stuck_jobs).and_raise(Exception)
          HoptoadNotifier.should_receive(:notify).with({:error_message=>"Exception: Exception", :request=>{:params=>"headmessage"}, :error_class=>"Exception"}).and_return(true)
          @reporter.process_loop(false)
        end
      end

      describe "less than a minute" do
        it "should complete the steps" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return("headmessage")
          @reporter.should_receive(:process_head_message).with("headmessage").and_return(true)
          @reporter.should_not_receive(:check_for_stuck_jobs)
          @reporter.should_receive(:minute_ago?).and_return(false)
          @reporter.process_loop(false)
          @reporter.started.should be_instance_of(Time)
        end
      end

      describe "more than a minute" do
        it "should complete the steps" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return("headmessage")
          @reporter.should_receive(:process_head_message).with("headmessage").and_return(true)
          @reporter.should_receive(:check_for_stuck_jobs).and_return(true)
          @reporter.should_receive(:minute_ago?).and_return(true)
          @reporter.process_loop(false)
          @reporter.started.should be_instance_of(Time)
        end
      end
    end

    describe "with no message" do
      describe "less than a minute" do
        it "should complete the steps" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return(nil)
          @reporter.should_receive(:sleep).with(1).and_return(true)
          @reporter.should_receive(:minute_ago?).and_return(false)
          @reporter.should_not_receive(:check_for_stuck_jobs)
          @reporter.process_loop(false)
          @reporter.started.should be_instance_of(Time)
        end
      end
      
      describe "more than a minute" do
        it "should complete the steps" do
          MessageQueue.should_receive(:get).with(:name => 'head', :peek => true).and_return(nil)
          @reporter.should_receive(:sleep).with(1).and_return(true)
          @reporter.should_receive(:minute_ago?).and_return(true)
          @reporter.should_receive(:check_for_stuck_jobs).and_return(true)
          @reporter.process_loop(false)
          @reporter.started.should be_instance_of(Time)
        end
      end
    end
  end
  
  describe "minute_ago?" do
    it "should return false if now less than 1 minute ago" do
      time_now = Time.now
      Time.stub!(:now).and_return(time_now)
      @reporter.started = time_now
      @reporter.minute_ago?.should be_false
      @reporter.started.should be_instance_of(Time)
    end

    it "should return true if now more than 1 minute ago" do
      time_then = 5.minutes.ago
      time_now = Time.now
      Time.stub!(:now).and_return(time_now)
      @reporter.started = time_then
      @reporter.minute_ago?.should be_true
      @reporter.started.should be_instance_of(Time)
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

  describe "build report" do
    it "should return a hash parsed by YAML" do
      message = mock("message")
      message.should_receive(:body).and_return("--- :thing:thing")
      YAML.should_receive(:load).with("--- :thing:thing").and_return({:thing => "thing"})
      @reporter.build_report(message).should == {:thing => "thing"}
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
      HoptoadNotifier.should_receive(:notify).with({:request=>{:params=>"id"}, :error_message=>"Job Load Error: Exception", :error_class=>"Invalid Job"}).and_return(true)
      Job.stub!(:find).and_raise(Exception)
      job = @reporter.load_job("id")
      job.should  be_nil
    end
  end
  
  describe "check job status" do
    before(:each) do
      @report = mock("report")
      @report.should_receive(:[]).with(:job_id).and_return(1234)
      @job = mock_model(Job)
    end
    describe "processed and not complete" do
      it "should update the job status and send a pack request" do
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @job.should_receive(:processed?).and_return(true)
        @job.should_receive(:complete?).and_return(false)
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
    describe "don't send message if nil" do
      it "should not be processed" do
        @reporter.should_receive(:load_job).with(1234).and_return(nil)
        @job.should_not_receive(:processed?)
        @job.should_not_receive(:complete?)
        @job.should_not_receive(:save)
        @job.should_not_receive(:send_pack_request)
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
      Time.stub!(:now).and_return(1)
    end
    describe "success" do
      it "should have a valid job link" do
        @reporter.should_receive(:create_job_link).and_return("job_link")
        @job.should_receive(:link=).with("job_link").and_return(true)
        @job.should_receive(:status=).with("Complete").and_return(true)
        @job.should_receive(:finished_at=).with(1.0).and_return(true)
        @job.should_receive(:save!).and_return(true)
        @job.should_receive(:remove_s3_working_folder).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.should_receive(:load_job).with(1234).and_return(@job)
        @reporter.set_job_download_link(@report, @message)
      end
    end

    describe "failure" do
      it "should not set a link and delete the message" do
        @job.should_not_receive(:save!)
        @job.should_not_receive(:remove_s3_working_folder)
        @message.should_receive(:delete).and_return(true)
        @reporter.should_receive(:load_job).with(1234).and_return(nil)
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
        @chunk.should_receive(:save!).and_return(true)
        @chunk.should_receive(:send_process_message).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.update_chunk("report", @message, true)
      end
    end

    describe "success for update" do
      it "should update a chunk" do
        @chunk.should_receive(:save!).and_return(true)
        @chunk.should_not_receive(:send_process_message).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.update_chunk("report", @message)
      end
    end
  end

  describe "job status" do
    describe "success" do
      it "should update the status of the job" do
        @job = mock_model(Job)
        @job.should_receive(:status=).and_return(true)
        @message = mock("message")
        @report = mock("report")
        @report.should_receive(:[]).with(:job_id).and_return(1234)
        @reporter.should_receive(:load_job).with(1234).and_return(@job)

        @job.should_receive(:save!).and_return(true)
        @message.should_receive(:delete).and_return(true)
        @reporter.job_status(@report, @message, "status")
      end
    end

    describe "failure" do
      it "should delete the message if the job doesn't exist" do
        @job = mock_model(Job)
        @message = mock("message")
        @report = mock("report")
        @report.should_receive(:[]).with(:job_id).and_return(1234)
        @reporter.should_receive(:load_job).with(1234).and_return(nil)
        @job.should_not_receive(:save!)
        @job.should_not_receive(:status=)
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
