class TandemModification < ActiveRecord::Base

  belongs_to :tandem_parameter_file
  
  validates_presence_of :mass, :message => "^You must include the mass."
  validates_numericality_of :mass, :on => :create, :message => "is not a number"

  validates_presence_of :amino_acid, :message => "^You must include the amino acid(s)."


  def mass_string
    return nil if amino_acid =~ /^>/
    amino_acid.split('').inject("") {|s, a| s << "#{mass}@#{a},"; s }.chomp(',')
  end

  def motif_string
    return nil if !(amino_acid =~ /^>/)
    "#{mass}@"+amino_acid.gsub(/>/, '')
  end

end
