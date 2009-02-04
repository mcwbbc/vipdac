require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/datafiles/index.html.erb" do
  include DatafilesHelper
  
  before(:each) do
    datafiles = [stub_model(Datafile), stub_model(Datafile)].paginate :page => 1, :per_page => 2
    assigns[:datafiles] = datafiles
  end

  it "should render list of datafiles" do
    render "/datafiles/index.html.erb"
  end
end

