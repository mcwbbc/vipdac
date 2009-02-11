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
      download_file(local_mgf_file, remote_mgf_file)
      download_file(local_parameter_file, remote_parameter_file)
      generate_ez2_file
      zip_files
      send_file(bucket_object(local_zipfile), local_zipfile) # this will upload the file
    end
    ensure
      remove_item(PACK_DIR)
  end

  def manifest
    download_file(local_manifest, "#{message[:hash_key]}/manifest.yml")
    @manifest ||= YAML.load_file(local_manifest)
  end

  def download_results_files
    manifest.each do |file|
      download_file("#{PACK_DIR}/"+input_file(file), file)
    end
  end

  def local_manifest
    "#{PACK_DIR}/manifest.yml"
  end

  def local_zipfile
    "#{PACK_DIR}/#{message[:resultfile_name]}.zip"
  end

  def local_ez2file
    local_zipfile.gsub(".zip","")
  end

  def ez2_input
    "--input=#{PACK_DIR}"
  end

  def ez2_output
    "--output="+local_ez2file
  end

  def local_mgf_file
    "#{PACK_DIR}/#{message[:datafile]}"
  end

  def local_parameter_file
    "#{PACK_DIR}/#{PARAMETER_FILENAME}"
  end

  def zip_files
    Zip::ZipFile.open(local_zipfile, Zip::ZipFile::CREATE) { |zipfile|
      output_filenames.each do |filename|
        zipfile.add(input_file(filename), filename)
      end
    }
  end
  
  def bucket_object(file_path)
    "resultfiles/"+input_file(file_path)
  end

  def output_filenames
    # Review the contents of the directory, listing number of .mgf files that were found
    Dir["#{PACK_DIR}/*.{xml,csv,conf,ez2}"]
  end

end
