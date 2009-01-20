require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/search_databases/new.html.erb" do
  include SearchDatabasesHelper
  
  before(:each) do
    assigns[:search_database] = stub_model(SearchDatabase,
      :new_record? => true
    )
  end

  it "should render new form" do
    render "/search_databases/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", search_databases_path) do
    end
  end
end


