class AwsMessageQueue

  class << self

    def get_message(name, timeout)
      message = eval("#{name}_queue").receive(timeout) # we have one minute to process this message, or it goes back on the queue
      if message && message.body.blank?
        message.delete #delete it if it's blank... might cause issues
        return nil
      end
      message
    end

    def send_message(name, message)
      eval("#{name}_queue").send_message(message)
    end

    def node_queue_name
      "#{Aws.access_key}-vipdac-node"
    end

    def head_queue_name
      "#{Aws.access_key}-vipdac-head"
    end

    def created_chunk_queue_name
      "#{Aws.access_key}-vipdac-created-chunk"
    end

    def node_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @node_queue ||= Aws.sqs.queue(node_queue_name, true)
    end

    def head_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @head_queue ||= Aws.sqs.queue(head_queue_name, true)
    end

    def created_chunk_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @created_chunk_queue ||= Aws.sqs.queue(created_chunk_queue_name, true)
    end
  
  end

end