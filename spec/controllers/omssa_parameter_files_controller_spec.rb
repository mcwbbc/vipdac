require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OmssaParameterFilesController do

  describe "handling GET /omssa_parameter_files" do

    before(:each) do
      @parameter_file = mock_model(OmssaParameterFile)
      OmssaParameterFile.stub!(:find).and_return([@parameter_file])
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

    it "should find all omssa_parameter_files paginated" do
      OmssaParameterFile.should_receive(:find).with(:all, {:order=>"name", :offset=>0, :limit=>10}).and_return([@parameter_file])
      do_get
    end

    it "should assign the found omssa_parameter_files for the view" do
      do_get
      assigns[:omssa_parameter_files].should == [@parameter_file]
    end
  end

  describe "handling GET /omssa_parameter_file/1" do

    before(:each) do
      @omssa_parameter_file = mock_model(OmssaParameterFile)
      OmssaParameterFile.stub!(:find).and_return(@omssa_parameter_file)
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

    it "should find the omssa_parameter_file requested" do
      OmssaParameterFile.should_receive(:find).with("1").and_return(@omssa_parameter_file)
      do_get
    end

    it "should assign the found omssa_parameter_file for the view" do
      do_get
      assigns[:omssa_parameter_file].should equal(@omssa_parameter_file)
    end

    it "should show the index page for an invalid omssa_parameter_file" do
      OmssaParameterFile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get
      response.should redirect_to(omssa_parameter_files_url)
    end
  end

  describe "handling GET /omssa_parameter_files/new" do

    before(:each) do
      @omssa_parameter_file = mock_model(OmssaParameterFile)
      OmssaParameterFile.stub!(:new).and_return(@omssa_parameter_file)
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

    it "should create an new omssa_parameter_file" do
      OmssaParameterFile.should_receive(:new).and_return(@omssa_parameter_file)
      do_get
    end

    it "should not save the new omssa_parameter_file" do
      @omssa_parameter_file.should_not_receive(:save)
      do_get
    end

    it "should assign the new omssa_parameter_file for the view" do
      do_get
      assigns[:omssa_parameter_file].should equal(@omssa_parameter_file)
    end
  end

  describe "handling POST /omssa_parameter_files" do
    before(:each) do
      @omssa_parameter_file = mock_model(OmssaParameterFile, :to_param => "1")
      OmssaParameterFile.stub!(:new).and_return(@omssa_parameter_file)
    end

    describe "with successful save" do
      before(:each) do
        @omssa_parameter_file.should_receive(:ions=).with("1,3").and_return(true)
      end
      def do_post
        @omssa_parameter_file.should_receive(:save).and_return(true)
        post :create, :omssa_parameter_file => {}, :ion1 => 1, :ion3 => 3
      end

      it "should create a new omssa_parameter_file" do
        OmssaParameterFile.should_receive(:new).with({}).and_return(@omssa_parameter_file)
        do_post
      end

      it "should redirect to the omssa_parameter_files_url" do
        do_post
        response.should redirect_to(omssa_parameter_files_url)
      end
    end

    describe "with failed save" do
      def do_post
        @omssa_parameter_file.should_receive(:save).and_return(false)
        post :create, :omssa_parameter_file => {}
      end

      it "should re-render 'new'" do
        @omssa_parameter_file.stub!(:ions=).and_return(true)
        do_post
        response.should render_template('new')
      end
    end
  end

  describe "handling DELETE /omssa_parameter_files/1" do

    before(:each) do
      @omssa_parameter_file = mock_model(OmssaParameterFile, :destroy => true)
      OmssaParameterFile.stub!(:find).and_return(@omssa_parameter_file)
    end

    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the omssa_parameter_file requested" do
      OmssaParameterFile.should_receive(:find).with("1").and_return(@omssa_parameter_file)
      do_delete
    end

    it "should call destroy on the found omssa_parameter_file" do
      @omssa_parameter_file.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the omssa_parameter_files list" do
      do_delete
      response.should redirect_to(omssa_parameter_files_url)
    end

    it "should show the index page for an invalid omssa_parameter_file" do
      OmssaParameterFile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(omssa_parameter_files_url)
    end

  end


end
