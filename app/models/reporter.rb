class Reporter

  def process_loop(looping_infinitely = true)
    begin
      @created_message = fetch_created_message
      if @created_message
        process_created_message(@created_message)
      else
        @message = fetch_head_message
        if @message
          process_head_message(@message)
        else
          sleep(30)
        end
      end
    end while looping_infinitely
  end

  def build_report(message)
     YAML.load(message.body)
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

  def process_created_message(message)
    update_chunk(build_report(message), message, true)
  end

  def fetch_created_message
    message = Aws.created_chunk_queue.receive(60) # we have one minutes to process this message, or it goes back on the queue
    if message && message.body.blank?
      message.delete #delete it if it's blank... might cause issues
      return nil
    end
    message
  end

  def fetch_head_message
    message = Aws.head_queue.receive(60) # we have one minutes to process this message, or it goes back on the queue
    if message && message.body.blank?
      message.delete #delete it if it's blank... might cause issues
      return nil
    end
    message
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
    job.status = status
    job.save
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
  end

end