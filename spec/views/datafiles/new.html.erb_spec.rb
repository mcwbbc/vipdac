require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/datafiles/new.html.erb" do
  include DatafilesHelper
  
  before(:each) do
    assigns[:datafile] = stub_model(Datafile,
      :new_record? => true
    )
  end

  it "should render new form" do
    render "/datafiles/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", datafiles_path) do
    end
  end
end


