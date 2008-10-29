class Chunk < ActiveRecord::Base

  belongs_to :job

  validates_presence_of :job_id
  validates_presence_of :chunk_key

  named_scope :pending, :conditions => ['started_at = ?', 0]
  named_scope :working, :conditions => ['started_at > ? AND finished_at = ?', 0, 0]
  named_scope :complete, :conditions => ['started_at > ? AND finished_at > ?', 0, 0]
  named_scope :incomplete, :conditions => ['finished_at = ?', 0]

  def status
    return "Created" if (started_at == 0)
    return "Working" if (finished_at == 0)
    "Complete"
  end
  
  def finished?
    (finished_at > 0)
  end
  
  def send_process_message
    hash = { :type => PROCESS,
             :chunk_count => chunk_count,
             :bytes => bytes,
             :sendtime => sent_at,
             :chunk_key => chunk_key,
             :job_id => job.id,
             :searcher => job.searcher,
             :filename => filename,
             :bucket_name => Aws.bucket_name,
             :parameter_filename => parameter_filename
           }
    Aws.send_node_message(hash.to_yaml)
  end
  
  def self.reporter_chunk(report)
    chunk = Chunk.find_or_create_by_chunk_key(report[:chunk_key])
    chunk.job_id = report[:job_id]
    chunk.instance_id = report[:instance_id]
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
