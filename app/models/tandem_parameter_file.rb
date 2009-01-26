class TandemParameterFile < ActiveRecord::Base
  
  TAXONOMY_FILE = "#{RAILS_ROOT}/config/tandem_config/taxonomy.xml"
  
  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :taxon, :message => "^Taxonomy is required"

  validates_uniqueness_of :name, :message => "^The name you entered is already taken"
  
  validates_length_of :ions, :minimum => 2, :too_short  => "^You must select at least {{count}} ions"

  has_many :tandem_modifications, :dependent => :destroy

  after_destroy :remove_from_simpledb

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
    ['CNBr', 'N|[X]']
  ]

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

  def self.page(page=1, limit=10)
    paginate(:page => page,
             :order => 'name',
             :per_page => limit
    )
  end

  def taxon_xml
    %Q(<note type="input" label="protein, taxon">#{taxon}</note>)
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

  def self.import_from_simpledb
    records = SearchParameterGroup.all_for("xtandem")
    records.each do |record|
      record.reload
      parameter_file = TandemParameterFile.new
      parameter_file.name = Aws.decode(record['name'])
      parameter_file.taxon = Aws.decode(record['taxon'])
      parameter_file.enzyme = Aws.decode(record['enzyme'])
      parameter_file.n_terminal = Aws.decode(record['n_terminal'])
      parameter_file.c_terminal = Aws.decode(record['c_terminal'])
      parameter_file.setup_ions(Aws.decode(record['ions']))
      if parameter_file.save
        # create the modifications
        parameter_file.create_modifications(Aws.decode(record['modifications']))
      end # don't care if it doesn't save, since it's most likely a name conflict
    end
  end

  def create_modifications(yaml_string)
    if yaml_string
      modifications = YAML.load(yaml_string)
      modifications.each do |m|
        tandem_modifications.create(:amino_acid => m['amino_acid'], :mass => m['mass'])
      end
    end
  end

  def setup_ions(yaml_string)
    hash = YAML.load(yaml_string)
    IONS.each do |ion|
      ion_string = "#{ion.downcase}_ion"
      self[ion_string] = hash[ion_string]
    end
  end

  def remove_from_simpledb
    record = SearchParameterGroup.for_name_and_searcher(name, "xtandem")
    record.delete if record
  end

  def save_to_simpledb
    SearchParameterGroup.new_for(parameter_hash, "xtandem")
  end

  def parameter_hash
    parameters = {}
    parameters['name'] = Aws.encode(name)
    parameters['taxon'] = Aws.encode(taxon)
    parameters['enzyme'] = Aws.encode(enzyme)
    parameters['n_terminal'] = Aws.encode("#{n_terminal}")
    parameters['c_terminal'] = Aws.encode("#{c_terminal}")
    parameters['ions'] = Aws.encode(yaml_ions)
    parameters['modifications'] = Aws.encode(yaml_modifications)
    parameters
  end

  def yaml_modifications
    if tandem_modifications.any?
      array = tandem_modifications.inject([]) do |a, mod|
        a << {'mass' => "#{mod.mass}", 'amino_acid' => "#{mod.amino_acid}"}
        a
      end
      array.to_yaml
    end
  end

  def yaml_ions
    hash = IONS.inject({}) do |h, ion|
      ion_string = "#{ion.downcase}_ion"
      h[ion_string] = instance_eval(ion_string)
      h
    end
    hash.to_yaml
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
