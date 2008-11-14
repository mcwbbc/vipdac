class Reporter

  def process_loop(looping_infinitely = true)
    @started = Time.now
    begin
      @message = MessageQueue.get(:name => 'head', :peek => true)
      if @message
        process_head_message(@message)
        @started = Time.now
      else
        check_for_stuck_chunks if minute_ago?(@started)
      end
    end while looping_infinitely
  end

  def minute_ago?(time)
    time.to_f < (Time.now.to_f - 60)
  end

  def build_report(message)
     YAML.load(message.body)
  end

  def process_head_message(message)
      report = build_report(message)
      message_type = report[:type]
      case message_type
        when START
          update_chunk(report, message)
        when FINISH
          update_chunk(report, message)
          check_job_status(report)
        when CREATED
          update_chunk(report, message, true)
        when JOBUNPACKING
          job_status(report, message, "Unpacking")
        when JOBUNPACKED
          job_status(report, message, "Processing")
        when DOWNLOAD
          set_job_download_link(report, message)
      end
  end

  def check_for_stuck_chunks
    Job.incomplete.each do |job|
      job.resend_stuck_chunks if job.stuck?
    end
  end

  def run
    node = Node.new(:instance_type => Aws.instance_type, :instance_id => Aws.instance_id)
    node.save
    write_pid
    process_loop
  end

  def logger
    log_file = File.join(RAILS_ROOT, 'log', 'reporter.log')
    @logger ||= Logger.new(log_file)
  end
  
  def write_pid
    pid_file = File.join(RAILS_ROOT, 'log', 'reporter.pid')
    File.open(pid_file,"w") do |file|
      file.puts($$)
    end
  end

  def create_job_link(report, job)
    "http://s3.amazonaws.com/#{report[:bucket_name]}/completed-jobs/#{job.output_file}"
  end

  def set_job_download_link(report, message)
    job = load_job(report[:job_id])
    job.link = create_job_link(report, job)
    job.save
    message.delete
    job.remove_s3_working_folder
  end
  
  def check_job_status(report)
    job = load_job(report[:job_id])
    if ((job.processed?) && !(job.complete?))
      job.status = "Complete"
      job.finished_at = Time.now.to_f
      job.save
      job.send_pack_request   # Send a job complete message to the workers, and have one of them download and zip up the results files
    end
  end

  def job_status(report, message, status)
    job = load_job(report[:job_id])
    if job
      job.status = status
      job.save
    end
    message.delete
  end

  def update_chunk(report, message, process_message=false)
    chunk = Chunk.reporter_chunk(report)
    chunk.save
    chunk.send_process_message if process_message
    message.delete
  end

  def load_job(id)
    Job.find(id)
    rescue Exception => e
      logger.error {"#{e.inspect}"}
      logger.error {"#{e.backtrace.join('\n')}"}
      logger.error {"INVALID JOB ID!: #{e}"}
      nil
  end

end