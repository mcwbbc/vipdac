class OmssaPacker < Packer

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

  def generate_ez2_file
    OmssaPacker.run_omssa_aws2ez2_unix(ez2_parameter_string)
  end

  def local_mgf_file
    "#{PACK_DIR}/#{message[:datafile]}"
  end

  def local_parameter_file
    "#{PACK_DIR}/#{PARAMETER_FILENAME}"
  end

  def ez2_parameter_string
    params = ""
    params << ez2_input+" "
    params << ez2_output+" "
    params << ez2_mgf+" "
    params << ez2_db+" "
    params << ez2_mods
  end

  def ez2_input
    "--input=#{PACK_DIR}"
  end

  def ez2_output
    "--output="+local_ez2file
  end

  def ez2_mods
    "--mods=#{OMSSA_PATH}/mods.xml"
  end

  def ez2_mgf
    "--mgf="+Dir["#{PACK_DIR}/*.mgf"].first
  end

  def local_ez2file
    local_zipfile.gsub(".zip","")
  end

  def ez2_db
    parameters = File.read("#{PACK_DIR}/parameters.conf")
    db = parameters.match(/dbs\/(.+?) /)[1]
    "--db=#{DB_PATH}/#{db}"
  end

  def self.run_omssa_aws2ez2_unix(parameters)
    %x{ perl /pipeline/vipdac/lib/omssa_aws2ez2_unix.pl #{parameters} }
  end

end