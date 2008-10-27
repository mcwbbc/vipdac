class NodeRunner

  class << self
    def run(arguments)
      node_number = arguments[0].blank? ? 1 : arguments[0]
      logger = setup_logger
      logger.debug("Launching node-#{node_number} with pid #{$$}")
      check_configuration
      setup_bucket
      write_pid_file(node_number)
      launch_watcher
    end

    def check_configuration
      config = AwsParameters.run
      # Abort if AWS access key id or secret access key were not provided
      if !config.has_key?('aws_access') || !config.has_key?('aws_secret') || !config.has_key?('instance-id') then
        raise "Instance must be launched with aws_access, aws_secret and instance_id parameters, but got: #{config.to_s}"
      else
        true
      end
    end

    def setup_logger
      Logger.new("/pipeline/pipeline.log")
    end

    def launch_watcher
      @watcher = Watcher.new
      @watcher.run
    end

    def pid_filename(node)
      File.join('/pipeline', "node-#{node}.pid")
    end

    def write_pid_file(node)
      File.open(pid_filename(node),"w") do |file|
        file.puts($$)
      end
    end

    def setup_bucket
      bucket = Aws.create_bucket
    end

  end

end