class OmssaParameterFile < ActiveRecord::Base

  attr_accessor :searcher
  
  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :database, :message => "^Please select a database"
  validates_presence_of :enzyme, :message => "^Enzyme is required"
  validates_presence_of :missed_cleavages, :message => "^Please specify the number of missed cleavages"
  validates_presence_of :precursor_tol, :message => "^Please specify the precursor tolerance"
  validates_presence_of :product_tol, :message => "^Please specify the product tolerance"
  validates_presence_of :product_search, :message => "^Please select the product search type"
  validates_presence_of :precursor_search, :message => "^Please select the precursor search type"
  validates_presence_of :minimum_charge, :message => "^Please specify the minimun charge"
  validates_presence_of :max_charge, :message => "^Please specify the maxumum charge"
  
  validates_uniqueness_of :name, :message => "^The name you entered is already taken"
  
  validates_length_of :ions, :minimum => 2, :too_short  => "^You must select at least {{count}} ions", :tokenizer => lambda {|str| str.scan(/\d/)}

  PARAMETER_PATH = "#{RAILS_ROOT}/tmp/"

  before_save :set_modification_as_string
  after_destroy :remove_from_simpledb

  def set_modification_as_string
    self.modifications = convert_modifications_to_string
  end
  
  def convert_modifications_to_string
    self.modifications.join(',') unless self.modifications == nil
  end

  def convert_modifications_to_array
    self.modifications.split(',') unless self.modifications == nil
  end

  def self.page(page=1, limit=10)
    paginate(:page => page,
             :order => 'name',
             :per_page => limit
    )
  end

  def self.import_from_simpledb
    records = SearchParameterGroup.all_for("omssa")
    records.each do |record|
      record.reload
      parameter_file = OmssaParameterFile.new
      record.attributes.keys.each do |key|
        parameter_file["#{key}"] = Aws.decode(record["#{key}"])
      end
      parameter_file.modifications = parameter_file.convert_modifications_to_array
      parameter_file.save
    end
  end

  def parameter_hash
    parameters = {}
    attributes.keys.each do |key|
      parameters["#{key}"] = Aws.encode("#{attributes[key]}")
    end
    parameters.delete("id")
    parameters
  end

  def save_to_simpledb
    SearchParameterGroup.new_for(parameter_hash, "omssa")
  end

  def remove_from_simpledb
    record = SearchParameterGroup.for_name_and_searcher(name, "omssa")
    record.delete if record
  end
  
  # writes a parameter file
  def write_file(directory)
  
    options = database_option
    options << enzyme_option
    options << cleavage_option
    options << precursor_tol_option
    options << product_tol_option
    options << precursor_search_option
    options << product_search_option
    options << minimum_charge_option
    options << max_charge_option
    options << ion_option
    options << modification_option
    options << hidden_options
    
    File.open(directory + PARAMETER_FILENAME, "w") do |file|
      file.puts(options)
    end
  end
  
  # returns an array of values for each ion in the comma delimited list
  def split_ions
    self.ions.split(',') rescue []
  end

  def database_option
    "-d /pipeline/dbs/#{self.database} "
  end
  
  def enzyme_option
    "-e #{self.enzyme} "
  end
  
  def cleavage_option
    "-v #{self.missed_cleavages} "
  end
  
  def precursor_tol_option
    "-te #{self.precursor_tol} "
  end
  
  def product_tol_option
    "-to #{self.product_tol} "
  end
  
  def precursor_search_option
    "-tem #{self.precursor_search} "
  end
  
  def product_search_option
    "-tom #{self.product_search} "
  end
  
  def minimum_charge_option
    "-zt #{self.minimum_charge} "
  end
  
  def max_charge_option
    "-zh #{self.max_charge} "
  end
  
  def ion_option
    "-i #{self.ions} "
  end
  
  def modification_option
    self.modifications != nil ? "-mv #{self.modifications} " : ''
  end
  
  def hidden_options
    "-tez 1 -zc 1 -zcc 1"
  end
  
  def mods_as_array
    self.modifications.split(',') unless self.modifications.blank?
  end
  
  def ions_as_array
    self.ions.split(',') unless self.ions.blank?
  end
  
end