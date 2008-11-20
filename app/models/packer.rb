class Packer

  include Utilities
  
  attr_accessor :message

  def initialize(message)
    self.message = message
  end

  def run
    begin
      make_directory(PACK_DIR)
      download_results_files
      zip_files
      send_file(bucket_object(local_zipfile), local_zipfile) # this will upload the finished file
    end
    ensure
      remove_item(PACK_DIR)
  end

  def manifest
    @manifest ||= YAML.load(Aws.s3i.get_object(Aws.bucket_name, "#{message[:job_id]}/manifest.yml"))
  end

  def download_results_files
    manifest.each do |file|
      download_file("#{PACK_DIR}/"+input_file(file), file)
    end
  end

  def local_zipfile
    "#{PACK_DIR}/"+message[:output_file]
  end

  def zip_files
    Zip::ZipFile.open(local_zipfile, Zip::ZipFile::CREATE) { |zipfile|
      output_filenames.each do |filename|
        zipfile.add(input_file(filename), filename)
      end
    }
  end
  
  def bucket_object(file_path)
    "completed-jobs/"+input_file(file_path)
  end

  def output_filenames
    # Review the contents of the directory, listing number of .mgf files that were found
    Dir["#{PACK_DIR}/*.{xml,csv,conf,ez2}"]
  end

end
