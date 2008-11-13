class MessageQueue

  class << self
    def get(hash)
      AwsMessageQueue.get_message(hash[:name], hash[:timeout])
    end

    def put(hash)
      AwsMessageQueue.send_message(hash[:name], hash[:message])
    end
  end

end
  
  