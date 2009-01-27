class Watcher

  include Utilities

  def convert_message_to_hash(message)
    YAML.load(message.body)    
  end

  def create_worker(hash)
    Worker.new(hash)    
  end

  def process(worker, message)
    message.delete if worker.run
  end

  def check_queue
    begin
      # If we have messages on the queue
      message = MessageQueue.get(:name => 'node', :peek => false)
      process(create_worker(convert_message_to_hash(message)), message)
    rescue Interrupt, SignalException
      # quit when we get one of these exceptions
      exit
    rescue Exception => e
      HoptoadNotifier.notify(
        :error_class => e.class.name,
        :error_message => "#{e.class.name}: #{e.message}", 
        :request => { :params => { :message => message } }
      ) unless self.ignore?(e)
      # ensure the message is deleted if we get a NoSuchKey error, since it will continue to fail
      message.delete if e.message =~ /NoSuchKey/
    end
  end

  def run(looping_infinitely = true)
    begin
      check_queue
    end while looping_infinitely
  end

  # Returns the default logger or a logger that prints to STDOUT. Necessary for manual
  # notifications outside of controllers.
  def logger
    @logger ||= Logger.new("/pipeline/pipeline.log")
  end

end

