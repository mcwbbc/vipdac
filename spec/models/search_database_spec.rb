require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchDatabase do
  before(:each) do
    @search_database = create_search_database
  end

  describe "create" do
    [:name, :keyword, :version].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_search_database(key => nil).should_not be_valid
      end
    end
  end

  describe "page" do
    it "should call paginate" do
      SearchDatabase.should_receive(:paginate).with({:page => 2, :order => 'created_at DESC', :per_page => 20}).and_return(true)
      SearchDatabase.page(2,20)
    end
  end

  protected
    def create_search_database(options = {})
      record = SearchDatabase.new({ :name => "database_name", :keyword => "keyword", :version => "version", :user_uploaded => true, :search_database_file_name => 'search_database_file', :search_database_content_type => 'text/plain', :search_database_file_size => 20 }.merge(options))
      record
    end

end
