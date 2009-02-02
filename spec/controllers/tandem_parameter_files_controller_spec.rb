require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TandemParameterFilesController do

  describe "handling GET /tandem_parameter_files" do

    before(:each) do
      @parameter_file = mock_model(TandemParameterFile)
      TandemParameterFile.stub!(:find).and_return([@parameter_file])
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
  
    it "should find all tandem_parameter_files paginated" do
      TandemParameterFile.should_receive(:find).with(:all, {:order=>"name", :offset=>0, :limit=>10}).and_return([@parameter_file])
      do_get
    end
  
    it "should assign the found tandem_parameter_files for the view" do
      do_get
      assigns[:tandem_parameter_files].should == [@parameter_file]
    end
  end

  describe "handling GET /tandem_parameter_file/1" do

    before(:each) do
      @tandem_parameter_file = mock_model(TandemParameterFile)
      TandemParameterFile.stub!(:find).and_return(@tandem_parameter_file)
    end
  
    def do_get
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render show template" do
      do_get
      response.should render_template('show')
    end
  
    it "should find the tandem_parameter_file requested" do
      TandemParameterFile.should_receive(:find).with("1").and_return(@tandem_parameter_file)
      do_get
    end
  
    it "should assign the found tandem_parameter_file for the view" do
      do_get
      assigns[:tandem_parameter_file].should equal(@tandem_parameter_file)
    end
    
    it "should show the index page for an invalid tandem_parameter_file" do
      TandemParameterFile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get
      response.should redirect_to(tandem_parameter_files_url)
    end
  end

  describe "handling GET /tandem_parameter_files/new" do

    before(:each) do
      @tandem_parameter_file = mock_model(TandemParameterFile)
      TandemParameterFile.stub!(:new).and_return(@tandem_parameter_file)
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
  
    it "should create an new tandem_parameter_file" do
      TandemParameterFile.should_receive(:new).and_return(@tandem_parameter_file)
      do_get
    end
  
    it "should not save the new tandem_parameter_file" do
      @tandem_parameter_file.should_not_receive(:save)
      do_get
    end

    it "should assign the new tandem_parameter_file for the view" do
      do_get
      assigns[:tandem_parameter_file].should equal(@tandem_parameter_file)
    end
  end

  describe "handling POST /tandem_parameter_files" do
    before(:each) do
      @mod = mock_model(TandemModification)
      @mod.stub!(:valid?).and_return(true)
      @tandem_parameter_file = mock_model(TandemParameterFile, :to_param => "1")
      @tandem_parameter_file.stub!(:tandem_modifications).and_return([@mod])
      TandemParameterFile.stub!(:new).and_return(@tandem_parameter_file)
    end
    
    describe "with successful save" do
      def do_post
        post :create, :tandem_parameter_file => {}
      end
  
      it "should create a new tandem_parameter_file" do
        @tandem_parameter_file.should_receive(:save).and_return(true)
        @tandem_parameter_file.should_receive(:persist).and_return(true)
        TandemParameterFile.should_receive(:new).with({}).and_return(@tandem_parameter_file)
        do_post
      end

      it "should redirect to the tandem_parameter_files_url" do
        @tandem_parameter_file.should_receive(:save).and_return(true)
        @tandem_parameter_file.should_receive(:persist).and_return(true)
        do_post
        response.should redirect_to(tandem_parameter_files_url)
      end
    end
    
    describe "with failed save" do
      def do_post
        post :create, :tandem_parameter_file => {}
      end
  
      it "should re-render 'new'" do
        @tandem_parameter_file.should_receive(:save).and_return(false)
        do_post
        response.should render_template('new')
      end
    end
  end

  describe "handling DELETE /tandem_parameter_files/1" do

    before(:each) do
      @tandem_parameter_file = mock_model(TandemParameterFile, :destroy => true)
      TandemParameterFile.stub!(:find).and_return(@tandem_parameter_file)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the tandem_parameter_file requested" do
      TandemParameterFile.should_receive(:find).with("1").and_return(@tandem_parameter_file)
      do_delete
    end
  
    it "should call destroy on the found tandem_parameter_file" do
      @tandem_parameter_file.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the tandem_parameter_files list" do
      do_delete
      response.should redirect_to(tandem_parameter_files_url)
    end

    it "should show the index page for an invalid tandem_parameter_file" do
      TandemParameterFile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(tandem_parameter_files_url)
    end

  end


end
