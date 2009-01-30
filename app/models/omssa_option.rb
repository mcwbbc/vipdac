class OmssaOption

  OPTIONS_FILE = "#{RAILS_ROOT}/config/omssa_config/omssa_options.xml"

  class << self
    attr_writer :modifications, :enzymes, :ions, :searches, :options_file

    def options_file
      @options_file ||= File.readlines(OPTIONS_FILE) rescue []
    end

    def modifications
      @modifications ||= generate_hash(/<mod id='(\d+)'>(.+?)</).sort
    end

    def enzymes
      @enzymes ||= generate_hash(/<enzyme id='(\d+)'>(.+?)</).sort
    end

    def ions
      @ions ||= generate_hash(/<ion id='(\d+)'>(.+?)</)
    end

    def searches
      @searches ||= generate_hash(/<search id='(\d+)'>(.+?)</).sort
    end

    def generate_hash(reg)
      options_file.inject({}) {|h, line| h[$2] = $1.to_i if line =~ reg; h }
    end

  end
end