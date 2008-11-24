class BeanstalkMessageQueue
  DEFAULT_PORT = 11300
  DEFAULT_PRIORITY = 65536
  TTR = 600

  class << self

    # peek is checks if a message exists
    # we need this for the reporter since it needs to fall through so we can do stuck chunk checks
    # the workers can just hang on waiting until something appears
    def get_message(name, peek=false)
      begin
        if peek
          get_queue(name).reserve if get_queue(name).peek_ready
        else
          get_queue(name).reserve
        end
      rescue Beanstalk::NotConnected => e
        sleep(10)
        retry if !(RAILS_ENV == 'test')
      end
    end

    # priority  lower is faster
    # ttr is time to release job once picked by a worker, this is like SQS when getting a message receive(ttr)
    # we give each job 10 mintues to finish by default
    def send_message(name, message, priority=DEFAULT_PRIORITY, delay=0, ttr=TTR)
      priority ||= DEFAULT_PRIORITY
      delay ||= 0
      ttr ||= TTR
      begin
        get_queue(name).put(message, priority, delay, ttr)
      rescue Beanstalk::NotConnected => e
        sleep(10)
        retry if !(RAILS_ENV == 'test')
      end
    end

    def server_ip
      @server_ip ||= begin
        config = AwsParameters.run
        config.key?('beanstalkd') ? config['beanstalkd'] : config['local-ipv4']
      end
    end

    def queue_hash
      @queues ||= {}
    end

    #To work with multiple queues you must tell beanstalk which queues
    #you plan on writing to (use), and which queues you will reserve jobs from
    #(watch). In this case we also want to ignore the default queue
    def get_queue(queue_name)
      queue_hash.key?(queue_name) ? queue_hash[queue_name] : create_queue(queue_name)
    end

    def create_queue(name)
      queue_hash[name] = Beanstalk::Pool.new(["#{server_ip}:#{DEFAULT_PORT}"], name)
    end

  end

end