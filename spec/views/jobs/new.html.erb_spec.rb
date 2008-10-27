require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/jobs/new.html.erb" do
  include JobsHelper
  
  before(:each) do
    @job = mock_model(Job)
    @omssa_parameter_file = mock_model(OmssaParameterFile)
    @omssa_parameter_file.stub!(:id).and_return(1)
    @omssa_parameter_file.stub!(:name).and_return("name")

    @parameter_files = [@omssa_parameter_file]

    errors = mock("errors", :empty? => true)

    @job.stub!(:new_record?).and_return(true)
    @job.stub!(:name).and_return("")
    @job.stub!(:parameter_file_id).and_return(nil)
    @job.stub!(:errors).and_return(errors)
    @job.stub!(:searcher).and_return("tandem")

    assigns[:job] = @job
    assigns[:parameter_files] = @parameter_files
  end

  it "should render new form" do
    render "/jobs/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", jobs_path) do
      with_tag("input#job_name[name=?]", "job[name]")
      with_tag("option[value=?]", "1")
    end
  end
end


