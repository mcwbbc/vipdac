require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resultfiles/index.html.erb" do
  include ResultfilesHelper
  
  before(:each) do
    resultfiles = [stub_model(Resultfile), stub_model(Resultfile)].paginate :page => 1, :per_page => 2
    assigns[:resultfiles] = resultfiles
  end

  it "should render list of resultfiles" do
    render "/resultfiles/index.html.erb"
  end
end

