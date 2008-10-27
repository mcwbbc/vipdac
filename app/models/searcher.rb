class Searcher
  
  include Utilities
  
  attr_accessor :parameter_file, :input_file, :output_file, :parameters

  def initialize(parameter_file, input_file, output_file)
    self.parameter_file = parameter_file
    self.input_file = input_file
    self.output_file = output_file
    self.parameters = File.read(parameter_file).strip
  end

end