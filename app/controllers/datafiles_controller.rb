class DatafilesController < ApplicationController

  before_filter :check_cancel, :only => [:create, :update]
  before_filter :load_datafile, :only => [:show, :destroy]

  # GET /datafiles
  def index
    @page = params[:page] || 1
    @datafiles = Datafile.page(@page)
  end

  # GET /datafiles/new
  def new
    @datafile = Datafile.new
  end

  # POST /datafiles
  def create
    @datafile = Datafile.new(params[:datafile])
    if @datafile.save
      @datafile.send_background_process_message
      flash[:notice] = 'Datafile was successfully created.'
      redirect_to(datafiles_url)
    else
      render :action => "new"
    end
  end

  # DELETE /datafile/1
  def destroy
    @datafile.destroy
    redirect_to(datafiles_url)
  end

  protected
    def load_datafile
      @datafile = Datafile.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to(datafiles_url) and return
    end

    def check_cancel
      redirect_to(datafiles_url) and return if (params[:commit] == "cancel")
    end
end
