class Aws

  INSTANCE_WORKERS = {'m1.small' => 1, 'c1.medium' => 2}

  class << self
    def amis
      @amis ||= {'i386' => ami_id}
    end

    def workers(instance_type)
      INSTANCE_WORKERS[instance_type]
    end

    def bucket_name
      keys['aws_access']+"-vipdac"
    end

    def node_queue_name
      keys['aws_access']+"-vipdac-node"
    end

    def head_queue_name
      keys['aws_access']+"-vipdac-head"
    end

    def created_chunk_queue_name
      keys['aws_access']+"-vipdac-created-chunk"
    end
    
    def current_hostname
      Rails.env.test? ? "test" : keys["public-hostname"]
    end

    def instance_type
      keys["instance-type"]
    end

    def instance_id
      keys["instance-id"]
    end

    def ami_id
      keys["ami-id"]
    end

    def local_hostname
      keys["local-hostname"]
    end

    def local_ipv4
      keys["local-ipv4"]
    end

    def public_keys
      keys["public-keys"]
    end

    def keypair
      if (key = /0=(.+)/.match(public_keys))
        key[1] 
      else
        nil
      end
    end

    def keys
      @keys ||= AwsParameters.run
    end

    def put_object(object_name, object_data, headers={})
      s3i.put(bucket_name, object_name, object_data, headers)
    end

    def get_object(object_name)
      s3i.get(bucket_name, object_name)
    end

    def delete_folder(folder_name)
      s3i.delete_folder(bucket_name, folder_name)
    end

    def delete_object(name)
      s3i.delete_folder(bucket_name, name)
    end

    def send_node_message(message)
      node_queue.send_message(message)
    end

    def send_head_message(message)
      head_queue.send_message(message)
    end

    def send_created_chunk_message(message)
      created_chunk_queue.send_message(message)
    end

    def create_bucket
      # create the storage bucket
      @bucket ||= s3i.create_bucket(bucket_name)
    end

    def node_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @node_queue ||= sqs.queue(node_queue_name, true)
    end

    def head_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @head_queue ||= sqs.queue(head_queue_name, true)
    end

    def created_chunk_queue
      # Create SQS object and queue so we can pass info to and from the named queue
      @created_chunk_queue ||= sqs.queue(created_chunk_queue_name, true)
    end

    def ec2
      @ec2 ||= RightAws::Ec2.new(keys['aws_access'], keys['aws_secret'])
    end

    def sqs
      @sqs ||= RightAws::SqsGen2.new(keys['aws_access'], keys['aws_secret'])
    end  

    def s3i
      @s3i ||= RightAws::S3Interface.new(keys['aws_access'], keys['aws_secret'])
    end

  end

end