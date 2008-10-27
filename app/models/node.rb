class Node < ActiveRecord::Base

  validates_presence_of :instance_type, :on => :create, :message => "must be selected"

  validates_uniqueness_of :instance_id

  named_scope :running, :conditions => ['active = ?', true], :order => 'created_at'

  def self.listing
    Aws.ec2.describe_instances    
  end

  def launch
    instance = Aws.ec2.launch_instances(Aws.ami_id, {:instance_type => instance_type, :key_name => 'ec2-keypair', :user_data => user_data}).first
    self.instance_id = instance[:aws_instance_id]
  end

  def self.active_nodes
    active = listing.inject([]) { |start, node| start << node if ((node[:aws_state] == "running") || (node[:aws_state] == "pending")); start }
  end

  def user_data
    "aws_access=#{Aws.keys['aws_access']},aws_secret=#{Aws.keys['aws_secret']},workers=#{Aws.workers(instance_type)},role=worker"
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
  end
  
  def remove_launched_instance
    if describe
      Aws.ec2.terminate_instances([instance_id])
    end
  end

  def chunks(limit=10)
    @chunks ||= Chunk.find(:all, :conditions => ["instance_id LIKE ?", "#{self.instance_id}%"], :order => "updated_at DESC", :limit => limit)
  end

end
