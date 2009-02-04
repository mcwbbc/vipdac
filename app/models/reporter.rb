class Reporter

  include Utilities

  attr_accessor :started

  # when we're first loaded, insert the node into the db
  # then save the PID and run the loop
  
  def run
    node = Node.new(:instance_type => Aws.instance_type, :instance_id => Aws.instance_id)
    node.save
    write_pid
    process_loop
  end

  def process
    begin
      @message = MessageQueue.get(:name => 'head', :peek => true)
      if @message
        process_head_message(@message)
      else
        sleep(1)
      end
      check_for_stuck_jobs if minute_ago?
    rescue Interrupt, SignalException
      # quit when we get one of these exceptions
      exit
    rescue Exception => e
      HoptoadNotifier.notify(
        :error_class => e.class.name, 
        :error_message => "#{e.class.name}: #{e.message}", 
        :request => { :params => @message }
      ) unless self.ignore?(e)
    end
  end

  # ignore certain exceptions

  def ignore?(exception) #:nodoc:
    ignore_these = HoptoadNotifier.ignore.flatten
    ignore_these.include?(exception.class) || ignore_these.include?(exception.class.name)
  end

  # loop forever checking the queue for messages and processing them
  # every minute we check for stuck jobs

  def process_loop(looping_infinitely = true)
    @started = Time.now
    begin
      process
    end while looping_infinitely
  end

  # has a minute passed?

  def minute_ago?
    if (@started < (Time.now - 60))
      @started = Time.now 
      true
    else
      false
    end
  end
  
  # convert the message body back into a ruby object from yaml string

  def build_report(message)
     YAML.load(message.body)
  end

  # process the message depending on the type

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
        when BACKGROUNDUPLOAD
          background_upload(report, message)
        when PROCESSDATABASE
          process_search_database(report, message)
        when PROCESSDATAFILE
          process_datafile(report, message)
        when JOBUNPACKING
          job_status(report, message, "Unpacking")
        when JOBUNPACKED
          job_status(report, message, "Processing")
        when JOBPACKING
          job_status(report, message, "Packing")
        when JOBPACKED
          set_job_download_link(report, message)
        else
          message.delete
      end
  end

  # check for stuck jobs, if we have any, set the priority to 50 so we process them right away
  # if the job is stuck because of packing, re-send the pack request

  def check_for_stuck_jobs
    Job.incomplete.each do |job|
      if job.stuck_chunks?
        job.priority = 50
        job.save!
        job.resend_stuck_chunks 
      elsif job.stuck_packing?
       job.send_pack_request
      end
    end
  end

  # write the PID to a file for monit
  
  def write_pid
    pid_file = File.join(RAILS_ROOT, 'log', 'reporter.pid')
    File.open(pid_file,"w") do |file|
      file.puts($$)
    end
  end

  # string for the download from S3 link
  
  def create_job_link(report, job)
    "http://s3.amazonaws.com/#{report[:bucket_name]}/completed-jobs/#{job.output_file}"
  end

  # update the job with a download link and marked complete

  def set_job_download_link(report, message)
    job = load_job(report[:job_id])
    if job
      job.status = "Complete"
      job.finished_at = Time.now.to_f
      job.link = create_job_link(report, job)
      job.save!
      job.remove_s3_working_folder
    end
    message.delete
  end
  
  # check to see if the job exists and is processed
  # if it's processed but not complete send the pack request

  def check_job_status(report)
    job = load_job(report[:job_id])
    if (job && ((job.processed?) && !(job.complete?)))
      job.send_pack_request   # Send a job complete message to the workers, and have one of them download and zip up the results files
    end
  end

  # process the database in the background

  def process_search_database(report, message)
    search_database = load_search_database(report[:database_id])
    if search_database
      search_database.process_and_upload
    end
    message.delete
  end

  # process the datafile in the background

  def process_datafile(report, message)
    datafile = load_datafile(report[:datafile_id])
    if datafile
      datafile.process_and_upload
    end
    message.delete
  end

  # upload the datafile in the background

  def background_upload(report, message)
    job = load_job(report[:job_id])
    if job
      job.status = "Uploading"
      job.save!
      job.background_s3_upload
    end
    message.delete
  end
  
  # update the job status depending on the message

  def job_status(report, message, status)
    job = load_job(report[:job_id])
    if job
      job.status = status
      job.save!
    end
    message.delete
  end

  # update the chunk status in the database

  def update_chunk(report, message, process_message=false)
    chunk = Chunk.reporter_chunk(report)
    chunk.save!
    chunk.send_process_message if process_message
    message.delete
  end

  # load a datafile from the DB

  def load_datafile(id)
    begin 
      Datafile.find(id)
    rescue Exception => e
      HoptoadNotifier.notify(
        :error_class => "Invalid Datafile", 
        :error_message => "Datafile Load Error: #{e.message}", 
        :request => { :params => id }
      )
      nil
    end
  end

  # load a search_database from the DB

  def load_search_database(id)
    begin 
      SearchDatabase.find(id)
    rescue Exception => e
      HoptoadNotifier.notify(
        :error_class => "Invalid Search Database", 
        :error_message => "Search Database Load Error: #{e.message}", 
        :request => { :params => id }
      )
      nil
    end
  end

  # load a job from the DB

  def load_job(id)
    begin 
      Job.find(id)
    rescue Exception => e
      HoptoadNotifier.notify(
        :error_class => "Invalid Job", 
        :error_message => "Job Load Error: #{e.message}", 
        :request => { :params => id }
      )
      nil
    end
  end

end