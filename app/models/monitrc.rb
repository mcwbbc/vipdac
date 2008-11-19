class Monitrc
  
  class << self
  
    def run
      logger.debug("Creating monitrc files for #{workers} workers")
      write_node_file
      symlink_reporter if master?
      symlink_beanstalkd if master?
    end

    def configuration
      AwsParameters.run
    end

    def logger
      Logger.new("/pipeline/pipeline.log")
    end

    def workers
      configuration['workers'].blank? ? 1 : configuration['workers'].to_i
    end

    def node_template
      File.read('/pipeline/vipdac/config/node.monitrc.template')
    end

    def assemble_node_text
      text = (1..workers).inject("") {|s, w| s << node_template.gsub(/ID/, w.to_s); s }
      text << "\n"
    end

    def write_node_file
      File.open('/pipeline/vipdac/config/node.monitrc', File::RDWR|File::CREAT) { |file| file.puts assemble_node_text}
    end

    def master?
      configuration['role'].blank?
    end

    def symlink_reporter
      File.symlink("/pipeline/vipdac/config/reporter.monitrc", "/etc/monit/reporter.monitrc") 
      File.symlink("/pipeline/vipdac/config/init-d-reporter", "/etc/init.d/reporter")
    end

    def symlink_beanstalkd
      File.symlink("/pipeline/vipdac/config/beanstalkd.monitrc", "/etc/monit/beanstalkd.monitrc") 
      File.symlink("/pipeline/vipdac/config/init-d-beanstalkd", "/etc/init.d/beanstalkd")
    end

    def symlink_thin
      File.symlink("/pipeline/vipdac/config/thin.monitrc", "/etc/monit/thin.monitrc") 
    end

  end
  
end