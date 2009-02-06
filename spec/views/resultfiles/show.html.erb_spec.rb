require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resultfiles/show.html.erb" do
  include ResultfilesHelper
  before(:each) do
    assigns[:resultfile] = @resultfile = stub_model(Resultfile)
  end

  it "should render attributes in <p>" do
    render "/resultfiles/show.html.erb"
  end
end

