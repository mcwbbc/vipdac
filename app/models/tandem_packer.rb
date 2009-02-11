class TandemPacker < Packer

  class << self
    def run_tandem_aws2ez2_unix(parameters)
      %x{ perl /pipeline/vipdac/lib/tandem_aws2ez2_unix.pl #{parameters} }
    end
  end

  def ez2_parameter_string
    params = ""
    params << ez2_input+" "
    params << ez2_output
  end

  def generate_ez2_file
    TandemPacker.run_tandem_aws2ez2_unix(ez2_parameter_string)
  end

end