class Node < ActiveRecord::Base

  validates_presence_of :instance_type, :on => :create, :message => "must be selected"

  validates_uniqueness_of :instance_id

  named_scope :running, :conditions => ['active = ?', true], :order => 'created_at'

  class << self
    def listing
      Aws.ec2.describe_instances    
    end

    def active_nodes
      active = listing.inject([]) { |start, node| start << node if ((node[:aws_state] == "running") || (node[:aws_state] == "pending")); start }
    end

    def status_hash
      listing.inject({}) {|h, n| h[n[:aws_instance_id]] = n[:aws_state]; h}
    end

    def launchable_nodes
      array = []
      1.upto(20) { |i| array << "#{i}" }
      array
    end

    def size_of_node(instance)
      find(:first, :select => 'instance_type', :conditions => ["instance_id LIKE ?", "#{instance}%"])
    end
  end

  def launch
    instance = Aws.ec2.launch_instances(Aws.ami_id, launch_parameters).first
    self.instance_id = instance[:aws_instance_id]
  end

  def launch_parameters
    parameters = {:instance_type => instance_type, :user_data => user_data}
    parameters[:key_name] = Aws.keypair if Aws.keypairs.any?
    parameters
  end

  def user_data
    data = "aws_access=#{Aws.access_key},aws_secret=#{Aws.secret_key},workers=#{Aws.workers(instance_type)},role=worker,beanstalkd=#{Aws.local_ipv4}" 
    data << ",folder=#{Aws.folder}" if Aws.folder
    data
  end
  
  def ami_type
    if (['m1.small', 'c1.medium'].include?(instance_type))
      'i386'
    else
      'x86_64'
    end
  end
  
  def describe
    Aws.ec2.describe_instances([instance_id]).first
    rescue RightAws::AwsError
      {:aws_state => "INVALID", :aws_reason => "INVALID", :aws_image_id => "INVALID", :dns_name => "INVALID", :aws_launch_time => "INVALID"}
  end
  
  def remove_launched_instance
    if describe
      Aws.ec2.terminate_instances([instance_id])
    end
  end

  def chunks(limit=10)
    Chunk.find_for_node(instance_id, limit)
  end

end
