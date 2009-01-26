class OmssaOption

  OPTIONS_FILE = "#{RAILS_ROOT}/config/omssa_config/omssa_options.xml"
  DATABASE_FILE = "#{RAILS_ROOT}/config/tandem_config/taxonomy.xml"

  class << self
    attr_writer :databases, :modifications, :enzymes, :ions, :searches, :options_file, :database_file

    def database_file
      @database_file ||= File.readlines(DATABASE_FILE) rescue []
    end

    def options_file
      @options_file ||= File.readlines(OPTIONS_FILE) rescue []
    end

    def modifications
      @modifications ||= generate_hash(/<mod id='(\d+)'>(.+?)</)
    end

    def enzymes
      @enzymes ||= generate_hash(/<enzyme id='(\d+)'>(.+?)</)
    end

    def ions
      @ions ||= generate_hash(/<ion id='(\d+)'>(.+?)</)
    end

    def searches
      @searches ||= generate_hash(/<search id='(\d+)'>(.+?)</)
    end

    def generate_hash(reg)
      options_file.inject({}) {|h, line| h[$2] = $1 if line =~ reg; h }
    end

  end
end