class Chunk < ActiveRecord::Base

  belongs_to :job

  validates_presence_of :job_id
  validates_presence_of :chunk_key

  named_scope :pending, :conditions => ['started_at = ?', 0]
  named_scope :working, :conditions => ['started_at > ? AND finished_at = ?', 0, 0]
  named_scope :complete, :conditions => ['started_at > ? AND finished_at > ?', 0, 0]
  named_scope :incomplete, :conditions => ['finished_at = ?', 0]
  named_scope :recent, {:limit => 10, :order => 'finished_at DESC, started_at DESC'}

  class << self
    def find_for_node(instance, limit)
      find(:all, :conditions => ["instance_id LIKE ?", "#{instance}%"], :order => "updated_at DESC", :limit => limit)
    end

    def reporter_chunk(report)
      chunk = Chunk.find_or_create_by_chunk_key(report[:chunk_key])
      chunk.job_id = report[:job_id]
      chunk.instance_id = report[:instance_id]
      chunk.instance_size = Node.size_of_node(report[:instance_id])
      chunk.filename = report[:filename]
      chunk.parameter_filename = report[:parameter_filename]
      chunk.bytes = report[:bytes].to_i
      chunk.chunk_key = report[:chunk_key]
      chunk.chunk_count = report[:chunk_count].to_i if report[:chunk_count]
      chunk.sent_at = report[:sendtime].to_f
      chunk.started_at = report[:starttime].to_f
      chunk.finished_at = (chunk.finished_at > 0) ? chunk.finished_at : report[:finishtime].to_f
      chunk
    end
  end
  
  def stats_hash
    h = {}
    h['instance_size'] = instance_size
    h['bytes'] = bytes
    h['sent_at'] = sent_at
    h['started_at'] = started_at
    h['finished_at'] = finished_at
    h
  end
  
  def status
    return "Created" if (started_at == 0)
    return "Working" if (finished_at == 0)
    "Complete"
  end
  
  def finished?
    (finished_at > 0)
  end

  def pretty_filename
    filename.split('/').last || ""
  end

  def send_process_message
    hash = { :type => PROCESS,
             :chunk_count => chunk_count,
             :bytes => bytes,
             :sendtime => sent_at,
             :chunk_key => chunk_key,
             :job_id => job.id,
             :hash_key => job.hash_key,
             :searcher => job.searcher,
             :search_database => job.search_database,
             :filename => filename,
             :bucket_name => Aws.bucket_name,
             :parameter_filename => parameter_filename
           }
    MessageQueue.put(:name => 'node', :message => hash.to_yaml, :priority => job.priority, :ttr => 1200)
  end
end
