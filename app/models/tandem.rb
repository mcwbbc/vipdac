class Tandem < Searcher

INPUT_XML = "#{PIPELINE_TMP}/input.xml"

INPUT = <<XML
<?xml version="1.0"?>
<bioml>
	<note type="input" label="list path, default parameters">/pipeline/bin/tandem/default_input.xml</note>
	<note type="input" label="list path, taxonomy information">/pipeline/bin/tandem/taxonomy.xml</note>
	<note type="input" label="output, path hashing">no</note>
	<note type="input" label="spectrum, path">DATA_SOURCE</note>
	<note type="input" label="output, path">OUTPUT</note>
PARAMETERS
</bioml>
XML

  def build_parameter_string
    INPUT.gsub(/PARAMETERS/, parameters).gsub(/DATA_SOURCE/, input_file).gsub(/OUTPUT/, "#{output_file}")
  end

  def write_parameter_file
    File.open(INPUT_XML, File::RDWR|File::CREAT) do |f|
      f << build_parameter_string
    end
  end

  # simple function to run tandem from the command line with a few basic parameters
  def run
    write_parameter_file
    Tandem.run_commandline_application
  end

  def self.run_commandline_application
    %x{ #{TANDEM_PATH}/tandem.exe #{INPUT_XML} }
  end

end