require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JobsController do

  describe "handling GET /jobs" do

    before(:each) do
      @job = mock_model(Job)
      Job.stub!(:find).and_return([@job])
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
  
    it "should find all jobs paginated" do
      Job.should_receive(:find).with(:all, {:order=>"created_at DESC", :offset=>0, :limit=>10}).and_return([@job])
      do_get
    end
  
    it "should assign the found jobs for the view" do
      do_get
      assigns[:jobs].should == [@job]
    end
  end

  describe "handling GET /jobs/1" do

    before(:each) do
      @job = mock_model(Job)
      Job.stub!(:find).and_return(@job)
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
  
    it "should find the job requested" do
      Job.should_receive(:find).with("1").and_return(@job)
      do_get
    end
  
    it "should assign the found job for the view" do
      do_get
      assigns[:job].should equal(@job)
    end
    
    it "should show the index page for an invalid job" do
      Job.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get
      response.should redirect_to(jobs_url)
    end
  end


  describe "handling GET /jobs/1/statistics" do

    before(:each) do
      @job = mock_model(Job)
      Job.stub!(:find).and_return(@job)
    end
  
    def do_statistics
      get :statistics, :id => "1"
    end

    describe "with success" do
      before(:each) do
        @job.should_receive(:send_statistics).and_return(true)
      end

      it "should redirect to index" do
        do_statistics
        response.should redirect_to(jobs_url)
      end

      it "should include a flash message" do
        do_statistics
        response.flash[:notice].should == "Job statistics successfully submitted."
      end

      it "should find the job requested" do
        Job.should_receive(:find).with("1").and_return(@job)
        do_statistics
      end

      it "should assign the found job for the view" do
        do_statistics
        assigns[:job].should equal(@job)
      end
    end
    
    it "should show the index page for an invalid job" do
      Job.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_statistics
      response.should redirect_to(jobs_url)
    end
  end


  describe "handling GET /jobs/update_parameter_files" do
    before(:each) do
      @job = mock_model(Job)
      Job.stub!(:new).and_return(@job)
      @omssa = mock_model(OmssaParameterFile)
      @omssa.stub!(:name).and_return("name")
      @tandem = mock_model(TandemParameterFile)
      @tandem.stub!(:name).and_return("name")
    end

    def do_post
      post :update_parameter_files, :job => {:searcher => "tandem"}
    end

    it "should be successful as tandem" do
      TandemParameterFile.should_receive(:find).with(:all, {:order=>"name"}).and_return([@tandem])
      do_post
      response.should be_success
    end
  
    it "should be successful as omssa" do
      OmssaParameterFile.should_receive(:find).with(:all, {:order=>"name"}).and_return([@omssa])
      post :update_parameter_files, :job => {:searcher => "omssa"}
      response.should be_success
    end
  end

  describe "handling GET /jobs/new" do

    before(:each) do
      @job = mock_model(Job)
      Job.stub!(:new).and_return(@job)
      @omssa = mock_model(OmssaParameterFile)
      OmssaParameterFile.should_receive(:find).with(:all, {:order=>"name"}).and_return([@omssa])
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
  
    it "should create an new job" do
      Job.should_receive(:new).and_return(@job)
      do_get
    end
  
    it "should not save the new job" do
      @job.should_not_receive(:save)
      do_get
    end

    it "should assign the new job for the view" do
      do_get
      assigns[:job].should equal(@job)
    end

    it "should assign the omssa parameter files for the view" do
      do_get
      assigns[:parameter_files].should == [@omssa]
    end
  end

  describe "handling POST /jobs" do

    before(:each) do
      @job = mock_model(Job, :to_param => "1")
      Job.stub!(:new).and_return(@job)
    end
    
    describe "with successful save" do
  
      def do_post
        @job.should_receive(:save).and_return(true)
        @job.should_receive(:launch).and_return(true)
        post :create, :job => {}
      end
  
      it "should create a new job" do
        Job.should_receive(:new).with({}).and_return(@job)
        do_post
      end

      it "should redirect to the jobs_url" do
        do_post
        response.should redirect_to(jobs_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @job.should_receive(:save).and_return(false)
        post :create, :job => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling DELETE /jobs/1" do

    before(:each) do
      @job = mock_model(Job, :destroy => true)
      Job.stub!(:find).and_return(@job)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the job requested" do
      Job.should_receive(:find).with("1").and_return(@job)
      do_delete
    end
  
    it "should call destroy on the found job" do
      @job.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the jobs list" do
      do_delete
      response.should redirect_to(jobs_url)
    end

    it "should show the index page for an invalid job" do
      Job.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(jobs_url)
    end

  end
end
