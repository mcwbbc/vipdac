class AwsParameters
  
#  AMAZON_DATA_URL = "169.254.169.254"
  AMAZON_DATA_URL = "amazon-user-data.local"

  DEFAULTS = {
      'workers' => 1
  }

  class << self

    def get_ec2_user_data
      # This is the address an EC2 instance calls to get user-data information
      response = Net::HTTP.get_response(URI.parse("http://#{AMAZON_DATA_URL}/latest/user-data"))
      case response
      when Net::HTTPSuccess then 
        response.body
      else
        ""
      end
    end

    def get_ec2_meta_data(key)
      # This is the address an EC2 instance calls to get user-data information
      key = "public-keys/" if key == "public-keys"
      response = Net::HTTP.get_response(URI.parse("http://#{AMAZON_DATA_URL}/latest/meta-data/#{key}"))
      case response
      when Net::HTTPSuccess then 
        response.body
      else
        ""
      end
    end

    def run
      @config ||= begin
        # Get and parse user-data (EC2 launch config)
        metadata = ['ami-id', 'instance-id', 'public-hostname', 'instance-type', 'local-hostname', 'local-ipv4', 'public-keys']
        config_str = self.get_ec2_user_data
        config = {}
        config_str.split(',').each{ |s| k,v = s.split('='); config[k] = v.chomp; }
        metadata.each {|meta| config[meta] = self.get_ec2_meta_data(meta)}
        DEFAULTS.merge(config)
      end
    end

    def load_yaml
      YAML.load_file(File.join(RAILS_ROOT, 'config', 'settings.yml'))
    end

  end

end