class MessageQueue

  class << self
    def get(hash)
#      AwsMessageQueue.get_message(hash[:name], hash[:timeout])
      BeanstalkMessageQueue.get_message(hash[:name], hash[:peek])
    end

    def put(hash)
#      AwsMessageQueue.send_message(hash[:name], hash[:message])
      BeanstalkMessageQueue.send_message(hash[:name], hash[:message], hash[:priority], 0, hash[:ttr])
    end
  end

end
