require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/jobs/show.html.erb" do
  include JobsHelper
  
  before(:each) do
    @job = mock_model(Job)
  
    chunks = mock("chunks", :pending => [], :working => [], :complete => [], :empty? => true, :size => 0)
    @job.stub!(:chunks).and_return(chunks)
    @job.stub!(:status).and_return("pending")
    @job.stub!(:searcher).and_return("tandem")
    @job.stub!(:launched_at).and_return(Time.now.to_f)
    @job.stub!(:finished_at).and_return(Time.now.to_f)
    @job.stub!(:name).and_return("name")

    assigns[:job] = @job
  end

  it "should render attributes on the page" do
    render "/jobs/show.html.erb"
  end
end

