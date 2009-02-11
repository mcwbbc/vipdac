class OmssaPacker < Packer

  class << self
    def run_omssa_aws2ez2_unix(parameters)
      %x{ perl /pipeline/vipdac/lib/omssa_aws2ez2_unix.pl #{parameters} }
    end
  end

  def generate_ez2_file
    OmssaPacker.run_omssa_aws2ez2_unix(ez2_parameter_string)
  end

  def ez2_parameter_string
    params = ""
    params << ez2_input+" "
    params << ez2_output+" "
    params << ez2_mgf+" "
    params << ez2_db+" "
    params << ez2_mods
  end

  def ez2_mods
    "--mods=#{OMSSA_PATH}/mods.xml"
  end

  def ez2_mgf
    "--mgf="+Dir["#{PACK_DIR}/*.mgf"].first
  end

  def ez2_db
    parameters = File.read("#{PACK_DIR}/parameters.conf")
    db = parameters.match(/dbs\/(.+?) /)[1]
    "--db=#{DB_PATH}/#{db}"
  end
end