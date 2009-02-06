require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResultfilesController do

  describe "handling GET /resultfiles" do

    before(:each) do
      @resultfile = mock_model(Resultfile)
      Resultfile.stub!(:find).and_return([@resultfile])
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
  
    it "should find all resultfiles paginated" do
      Resultfile.should_receive(:find).with(:all, {:order=>"name ASC", :offset=>0, :limit=>15}).and_return([@resultfile])
      do_get
    end
  
    it "should assign the found resultfiles for the view" do
      do_get
      assigns[:resultfiles].should == [@resultfile]
    end
  end

  describe "handling GET /resultfiles/1" do
    it "should expose the requested resultfile as @resultfile" do
      Resultfile.should_receive(:find).with("1").and_return(@resultfile)
      get :show, :id => "1"
      assigns[:resultfile].should equal(@resultfile)
    end
  end

  describe "handling DELETE /resultfiles/1" do

    before(:each) do
      @resultfile = mock_model(Resultfile, :destroy => true)
      Resultfile.stub!(:find).and_return(@resultfile)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the resultfile requested" do
      Resultfile.should_receive(:find).with("1").and_return(@resultfile)
      do_delete
    end
  
    it "should call destroy on the found resultfile" do
      @resultfile.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the resultfiles list" do
      do_delete
      response.should redirect_to(resultfiles_url)
    end

    it "should show the index page for an invalid resultfile" do
      Resultfile.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete
      response.should redirect_to(resultfiles_url)
    end

  end
end

