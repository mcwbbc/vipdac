require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/search_databases/index.html.erb" do
  include SearchDatabasesHelper
  
  before(:each) do
    search_databases = [stub_model(SearchDatabase), stub_model(SearchDatabase)].paginate :page => 1, :per_page => 2
    assigns[:search_databases] = search_databases
  end

  it "should render list of search_databases" do
    render "/search_databases/index.html.erb"
  end
end

