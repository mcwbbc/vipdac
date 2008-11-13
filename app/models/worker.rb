class Worker
  
  include Utilities
  
  attr_accessor :message
  
  def initialize(message)
    self.message = message
  end

  def run
    begin
      make_directory(PIPELINE_TMP)
      case message[:type]
        when PACK
          launch_packer
        when UNPACK
          launch_unpacker
        when PROCESS
          launch_process
      end
    end
    ensure
      remove_item(PIPELINE_TMP)
  end

  def launch_process
    starttime = Time.now.to_f
    download_file(local_input_filename, message[:filename])
    download_file(local_parameter_filename, message[:parameter_filename])
    send_message(START, starttime, 0.0)
    process_file
    until upload_output_file
      sleep(1)
    end
    finishtime = Time.now.to_f
    send_message(FINISH, starttime, finishtime)
  end

  def launch_unpacker
    unpacker = Unpacker.new(message)
    unpacker.run
  end

  def launch_packer
    packer = (message[:searcher] == "omssa") ? OmssaPacker.new(message) : TandemPacker.new(message)
    packer.run
  end

  def process_file
    searcher = nil
    case message[:searcher]
      when "omssa"
        searcher = Omssa.new(local_parameter_filename, local_input_filename, local_output_filename)
      when "tandem"
        searcher = Tandem.new(local_parameter_filename, local_input_filename, local_output_filename)
    end
    searcher.run
  end

  def upload_output_file
    Aws.put_object("#{message[:job_id]}/out/"+input_file(local_output_filename), File.open(local_output_filename))
  end

  def send_message(type, starttime, finishtime)
    hash = {:type => type, :bytes => message[:bytes], :filename => message[:filename], :parameter_filename => message[:parameter_filename], :sendtime => message[:sendtime], :chunk_key => message[:chunk_key], :job_id => message[:job_id], :instance_id => "#{Aws.instance_id}-#{$$}", :starttime => starttime, :finishtime => finishtime}
    MessageQueue.put(:name => 'head', :message => hash.to_yaml, :priority => 100)
  end
  
  def local_output_filename
    case message[:searcher]
      when "omssa"
        local_input_filename+"-out.csv"
      when "tandem"
        local_input_filename+"-out.xml"
    end
  end

  def local_input_filename
    "#{PIPELINE_TMP}/"+input_file(message[:filename])
  end

  def local_parameter_filename
    "#{PIPELINE_TMP}/"+input_file(message[:parameter_filename])
  end
  
end
