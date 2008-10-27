class Omssa < Searcher

  # simple function to run omssa from the command line with a few basic parameters
  def run
    %x{ #{OMSSA_PATH}/omssacl #{parameters} -fm #{input_file} -oc #{output_file} }
  end

end