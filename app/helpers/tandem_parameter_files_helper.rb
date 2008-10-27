module TandemParameterFilesHelper

  def add_modification_link(name)
    link_to_function(name) do |page|
      page.insert_html(:bottom, :tandem_modifications, :partial => 'tandem_modification', :object => TandemModification.new)
    end
  end

end
