class Watcher

  include Utilities

  def convert_message_to_hash(message)
    YAML.load(message.body)    
  end

  def create_worker(hash)
    Worker.new(hash)    
  end

  def process(worker, message)
    begin
      message.delete if worker.run
    rescue RightAws::AwsError => e
      message.delete
    end
  end

  def check_queue
    # If we have messages on the queue
    message = MessageQueue.get(:name => 'node', :peek => false)
    process(create_worker(convert_message_to_hash(message)), message)
  end

  def run(looping_infinitely = true)
    begin
      check_queue
    end while looping_infinitely
  end

end

