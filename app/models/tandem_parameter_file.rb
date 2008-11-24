class TandemParameterFile < ActiveRecord::Base
  
  TAXONOMY_FILE = "#{RAILS_ROOT}/config/tandem_config/taxonomy.xml"
  
  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :taxon, :message => "^Taxonomy is required"

  validates_uniqueness_of :name, :message => "^The name you entered is already taken"
  
  validates_length_of :ions, :minimum => 2, :too_short  => "^You must select at least {{count}} ions"

  has_many :tandem_modifications, :dependent => :destroy

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

  def self.taxonomies
    taxons = File.open(TAXONOMY_FILE).readlines.inject([]) {|array, line| array << $1 if line =~ /<taxon label="(\w+)"/; array}
    rescue
      []
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
