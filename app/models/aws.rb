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
      folder ? "#{folder}-#{access_key}-vipdac" : "#{access_key}-vipdac"
    end

    def current_hostname
      (RAILS_ENV == 'test') ? "test" : keys["public-hostname"]
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

    def access_key
      keys["aws_access"]
    end

    def secret_key
      keys["aws_secret"]
    end

    def folder
      keys["folder"] ? keys["folder"].downcase.gsub(/[^a-z0-9]+/i, '') : nil
    end

    def keypair
      if keypairs.any?
        keypairs.first[:aws_key_name]
      end
    end

    def keypairs
      begin
        ec2.describe_key_pairs
      rescue Exception
        []
      end
    end

    def keys
      @keys ||= AwsParameters.run
    end

    def put_object(object_name, object_data, headers={})
      s3i.put(bucket_name, object_name, object_data, headers)
    end

    def put_verified_object(object_name, object_data, md5, headers={})
      s3i.store_object_and_verify(:bucket => bucket_name, :key => object_name, :md5 => md5, :data => object_data, :headers => headers) 
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

    def create_bucket
      # create the storage bucket
      @bucket ||= s3i.create_bucket(bucket_name)
    end

    def ec2
      @ec2 ||= RightAws::Ec2.new(access_key, secret_key)
    end

    def sqs
      @sqs ||= RightAws::SqsGen2.new(access_key, secret_key)
    end  

    def s3i
      @s3i ||= RightAws::S3Interface.new(access_key, secret_key)
    end

    def sdb
      @sdb ||= RightAws::ActiveSdb.establish_connection(access_key, secret_key)
    end

  end

end