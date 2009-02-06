require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/jobs/show.html.erb" do
  include JobsHelper
  
  before(:each) do
    @job = mock_model(Job)
    datafile = mock("datafile", :uploaded_file_name => "uploaded.mgf")
    working = mock("working", :recent => [], :size => 0)
    complete = mock("complete", :recent => [], :size => 0)
  
    chunks = mock("chunks", :pending => [], :working => working, :complete => complete, :empty? => true, :size => 0)
    @job.stub!(:chunks).and_return(chunks)
    @job.stub!(:status).and_return("pending")
    @job.stub!(:searcher).and_return("tandem")
    @job.stub!(:datafile).and_return(datafile)
    @job.stub!(:priority).and_return(100)
    @job.stub!(:launched_at).and_return(Time.now.to_f)
    @job.stub!(:finished_at).and_return(Time.now.to_f)
    @job.stub!(:name).and_return("name")
    @job.stub!(:spectra_count).and_return(200)
    @job.stub!(:maximum_chunk_time).and_return(200)
    @job.stub!(:minimum_chunk_time).and_return(200)
    @job.stub!(:average_chunk_time).and_return(200)

    assigns[:job] = @job
  end

  it "should render attributes on the page" do
    render "/jobs/show.html.erb"
  end
end

