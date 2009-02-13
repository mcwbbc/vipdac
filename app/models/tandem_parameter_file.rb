class TandemParameterFile < ActiveRecord::Base
  
  include Utilities
  extend Utilities
  
  TAXONOMY_FILE = "#{RAILS_ROOT}/config/tandem_config/taxonomy.xml"
  
  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :database, :message => "^Database is required"

  validates_uniqueness_of :name, :message => "^The name you entered is already taken"
  
  validates_length_of :ions, :minimum => 2, :too_short  => "^You must select at least {{count}} ions"

  has_many :tandem_modifications, :dependent => :destroy

  after_destroy :delete

  IONS = ['A', 'B', 'C', 'X', 'Y', 'Z']

  ENZYMES = [ 
    ['None', '[X]|[X]'],
    ['Tripsin_KR', '[RK]|{P}'],
    ['Trypsin(K)', 'WK|P'],
    ['Trypsin(R)', 'MR|P'],
    ['LysC', 'K|[X]'],
    ['Asp-N', '[X]|D'],
    ['Chymotrypsin', '[FY]|{P}'],
    ['Formic Acid', 'D|[X]'],
    ['CNBr', 'M|[X]']
  ]

  class << self
    def page(page=1, limit=10)
      paginate(:page => page,
               :order => 'name',
               :per_page => limit
      )
    end

    def import
      files = TandemParameterFile.remote_file_list("tandem-parameter-records")
      files.each do |file|
        parameter_file = TandemParameterFile.new
        hash = YAML.load(parameter_file.retreive(file))
        modifications = hash["modifications"]
        hash.delete("modifications")
        parameter_file.attributes = hash
        if parameter_file.save && modifications
          parameter_file.create_modifications(modifications)
        end
      end
    end
  end

  def modification_attributes=(ma)
    ma.each do |a|
      self.tandem_modifications.build(a)
    end
  end

  def ions
    IONS.inject([]) {|a,i| a << instance_eval("#{i.downcase}_ion") if instance_eval("#{i.downcase}_ion") == true; a }
  end

  def ion_names
    IONS.inject("") {|a,i| a << "#{i}-ions " if instance_eval("#{i.downcase}_ion") == true; a }.chomp(" ")
  end

  def taxon_xml
    %Q(<note type="input" label="protein, taxon">#{database}</note>)
  end

  def enzyme_xml
    %Q(<note type="input" label="protein, cleavage site">#{enzyme}</note>)
  end

  def n_terminal_xml
    %Q(<note type="input" label="protein, cleavage N-terminal mass change">#{n_terminal}</note>)
  end

  def c_terminal_xml
    %Q(<note type="input" label="protein, cleavage C-terminal mass change">#{c_terminal}</note>)
  end

  def ion_xml
    IONS.inject("") do |s, ion|
      value = instance_eval("#{ion.downcase}_ion") ? "yes" : "no"
      s << %Q(<note type="input" label="scoring, #{ion.downcase} ions">#{value}</note>)
      s
    end
  end

  def mass_xml
    # generate the mass from the mods
    xml = ""
    if tandem_modifications.any?
      mass = tandem_modifications.inject("") {|s, mod| s << "#{mod.mass_string}," if mod.mass_string; s}.chomp(',')
      xml << %Q(<note type="input" label="residue, potential modification mass">#{mass}</note>) if !mass.blank?
    end
    xml
  end

  def motif_xml
    # generate the motif from the mods
    xml = ""
    if tandem_modifications.any?
      motif = tandem_modifications.inject("") {|s, mod| s << "#{mod.motif_string}," if mod.motif_string; s}.chomp(',')
      xml << %Q(<note type="input" label="residue, potential modification motif">#{motif}</note>) if !motif.blank?
    end
    xml
  end

  def create_modifications(modifications)
    modifications.each do |m|
      tandem_modifications.create(:amino_acid => m['amino_acid'], :mass => m['mass'])
    end
  end

  def setup_ions(yaml_string)
    hash = YAML.load(yaml_string)
    IONS.each do |ion|
      ion_string = "#{ion.downcase}_ion"
      self[ion_string] = hash[ion_string]
    end
  end

  def stats_hash
    h = parameter_hash
    h.delete("created_at")
    h.delete("updated_at")
    h['name'] = md5_item(name, false)
    h['database_size'] = SearchDatabase.size_of(h['database'])
    h
  end

  def parameter_hash
    parameters = attributes
    parameters["modifications"] = modifications_array
    parameters.delete("id")
    parameters
  end

  def persist
    send_verified_data("tandem-parameter-records/#{md5_item(name, false)}.yml", parameter_hash.to_yaml, md5_item(parameter_hash.to_yaml, false), {})
  end

  def delete
    Aws.delete_object("tandem-parameter-records/#{md5_item(name, false)}.yml")
  end

  def modifications_array
    if tandem_modifications.any?
      array = tandem_modifications.inject([]) do |a, mod|
        a << {'mass' => "#{mod.mass}", 'amino_acid' => "#{mod.amino_acid}"}
        a
      end
      array
    end
  end

  # writes a parameter file
  def write_file(directory)
    xml = ""
    xml << taxon_xml
    xml << enzyme_xml
    xml << n_terminal_xml if n_terminal
    xml << c_terminal_xml  if c_terminal
    xml << ion_xml
    xml << mass_xml
    xml << motif_xml
      
    File.open(directory + PARAMETER_FILENAME, "w") do |file|
      file.puts(xml)
    end
  end
end
