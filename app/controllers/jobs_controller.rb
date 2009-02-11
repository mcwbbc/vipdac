class JobsController < ApplicationController

#  before_filter :login_required
  before_filter :check_cancel, :only => [:create, :update]
  before_filter :load_job, :only => [:show, :statistics, :destroy]

  # GET /jobs
  def index
    @page = params[:page] || 1
    @jobs = Job.page(@page)
  end

  # GET /jobs/1
  def show
  end

  # GET /jobs/1/statistics
  def statistics
    # TODO: background http request to vipstats.mcw.edu/jobs/create
    flash[:notice] = 'Job statistics successfully submitted.'
    redirect_to(jobs_url)
  end

  # GET /jobs/new
  def new
    @job = Job.new(:spectra_count => 200)
    @parameter_files = OmssaParameterFile.find(:all, :order => 'name')
  end

  def update_parameter_files
    load_parameter_files
    render :update do |page|
      page.replace_html 'parameter_files', :partial => 'parameter_files', :object => @parameter_files
    end
  end

  # POST /jobs
  def create
    @job = Job.new(params[:job])

    if @job.save 
      @job.launch
      flash[:notice] = 'Job was successfully launched.'
      redirect_to(jobs_url)
    else
      load_parameter_files
      render :action => "new"
    end
  end

  # DELETE /jobs/1
  def destroy
    @job.destroy
    redirect_to(jobs_url)
  end

  protected
    def load_job
      @job = Job.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to jobs_url and return
    end

    def load_parameter_files
      searcher = params[:job][:searcher]

      if searcher == "tandem"
        @parameter_files = TandemParameterFile.find(:all, :order => 'name')
      else
        @parameter_files = OmssaParameterFile.find(:all, :order => 'name')
      end
    end

    def check_cancel
      redirect_to(jobs_url) and return if (params[:commit] == "cancel")
    end

end
