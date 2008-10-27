class Watcher

  include Utilities

  def fetch_message
    message = Aws.node_queue.receive(1800) # we have thirty minutes to process this message, or it goes back on the queue
    if message && message.body.blank?
      message.delete #delete it if it's blank... might cause issues
      return nil
    end
    message
  end

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
    message = fetch_message
    if message
      process(create_worker(convert_message_to_hash(message)), message)
    else
      sleep(15)
    end
  end

  def run(looping_infinitely = true)
    begin
      check_queue
    end while looping_infinitely
  end

end

