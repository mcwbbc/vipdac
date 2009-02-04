require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DatafilesController do

  describe "handling GET /datafiles" do

    before(:each) do
      @datafile = mock_model(Datafile)
      Datafile.stub!(:find).and_return([@datafile])
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
  
    it "should find all datafiles paginated" do
      Datafile.should_receive(:find).with(:all, {:order=>"name ASC", :offset=>0, :limit=>15}).and_return([@datafile])
      do_get
    end
  
    it "should assign the found datafiles for the view" do
      do_get
      assigns[:datafiles].should == [@datafile]
    end
  end

  describe "handling GET /datafiles/new" do

    before(:each) do
      @datafile = mock_model(Datafile)
      Datafile.stub!(:new).and_return(@datafile)
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
  
    it "should create an new datafile" do
      Datafile.should_receive(:new).and_return(@datafile)
      do_get
    end
  
    it "should not save the new datafile" do
      @datafile.should_not_receive(:save)
      do_get
    end

    it "should assign the new datafile for the view" do
      do_get
      assigns[:datafile].should equal(@datafile)
    end
  end

  describe "handling POST /datafiles" do

    before(:each) do
      @datafile = mock_model(Datafile, :to_param => "1")
      Datafile.stub!(:new).and_return(@datafile)
    end
    
    describe "with successful save" do
      before(:each) do
        @datafile.should_receive(:save).and_return(true)
        @datafile.should_receive(:send_background_process_message).and_return(true)
      end

      def do_post
        post :create, :datafile => {}
      end
  
      it "should create a new datafile" do
        Datafile.should_receive(:new).with({}).and_return(@datafile)
        do_post
      end

      it "should redirect to the datafiles_url" do
        do_post
        response.should redirect_to(datafiles_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @datafile.should_receive(:save).and_return(false)
        post :create, :datafile => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling DELETE /datafiles/1" do

    before(:each) do
      @datafile = mock_model(Datafile, :destroy => true)
      Datafile.stub!(:find).and_return(@datafile)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the datafile requested" do
      Datafile.should_receive(:find).with("1").and_return(@datafile)
      do_delete
    end
  
    it "should call destroy on the found datafile" do
      @datafile.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the datafiles list" do
      do_delete
      response.should redirect_to(datafiles_url)
    end

    it "should show the index page for an invalid datafile" do
      Datafile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(datafiles_url)
    end

  end
end
