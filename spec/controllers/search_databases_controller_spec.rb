require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchDatabasesController do

  describe "handling GET /search_databases" do

    before(:each) do
      @search_database = mock_model(SearchDatabase)
      SearchDatabase.stub!(:find).and_return([@search_database])
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all search_databases paginated" do
      SearchDatabase.should_receive(:find).with(:all, {:order=>"name ASC", :offset=>0, :limit=>15}).and_return([@search_database])
      do_get
    end
  
    it "should assign the found search_databases for the view" do
      do_get
      assigns[:search_databases].should == [@search_database]
    end
  end

  describe "handling GET /search_databases/new" do

    before(:each) do
      @search_database = mock_model(SearchDatabase)
      SearchDatabase.stub!(:new).and_return(@search_database)
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new search_database" do
      SearchDatabase.should_receive(:new).and_return(@search_database)
      do_get
    end
  
    it "should not save the new search_database" do
      @search_database.should_not_receive(:save)
      do_get
    end

    it "should assign the new search_database for the view" do
      do_get
      assigns[:search_database].should equal(@search_database)
    end
  end

  describe "handling POST /search_databases" do

    before(:each) do
      @search_database = mock_model(SearchDatabase, :to_param => "1")
      SearchDatabase.stub!(:new).and_return(@search_database)
    end
    
    describe "with successful save" do
      before(:each) do
        @search_database.should_receive(:save).and_return(true)
        @search_database.should_receive(:send_background_process_message).and_return(true)
      end

      def do_post
        post :create, :search_database => {}
      end
  
      it "should create a new search_database" do
        SearchDatabase.should_receive(:new).with({}).and_return(@search_database)
        do_post
      end

      it "should redirect to the search_databases_url" do
        do_post
        response.should redirect_to(search_databases_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @search_database.should_receive(:save).and_return(false)
        post :create, :search_database => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling DELETE /search_databases/1" do

    before(:each) do
      @search_database = mock_model(SearchDatabase, :destroy => true)
      SearchDatabase.stub!(:find).and_return(@search_database)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the search_database requested" do
      SearchDatabase.should_receive(:find).with("1").and_return(@search_database)
      do_delete
    end
  
    it "should call destroy on the found search_database" do
      @search_database.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the search_databases list" do
      do_delete
      response.should redirect_to(search_databases_url)
    end

    it "should show the index page for an invalid search_database" do
      SearchDatabase.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(search_databases_url)
    end

  end
end
