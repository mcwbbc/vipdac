require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/tandem_parameter_files/new.html.erb" do
  include TandemParameterFilesHelper
  
  before(:each) do
    @tandem_parameter_file = TandemParameterFile.new
    assigns[:tandem_parameter_file] = @tandem_parameter_file
  end

  it "should render new form" do
    render "/tandem_parameter_files/new.html.erb"
    response.should have_tag("form[action=?][method=post]", tandem_parameter_files_path) do
      with_tag("input#tandem_parameter_file_name[name=?]", "tandem_parameter_file[name]")
    end
  end
end


