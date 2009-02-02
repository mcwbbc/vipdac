class TandemParameterFilesController < ApplicationController

  before_filter :check_cancel, :only => [:create, :update]
  before_filter :load_tandem_parameter_file, :only => [:show, :destroy]

  # GET /tandem_parameter_file
  def index
    @page = params[:page] || 1
    @tandem_parameter_files = TandemParameterFile.page(@page)
  end

  # GET /tandem_parameter_file/1
  def show
  end

  # GET /tandem_parameter_file/new
  def new
    @tandem_parameter_file = TandemParameterFile.new(:b_ion => true, :y_ion => true)
  end

  # POST /tandem_parameter_file
  def create
    @tandem_parameter_file = TandemParameterFile.new(params[:tandem_parameter_file])

    if @tandem_parameter_file.save
      @tandem_parameter_file.persist
      flash[:notice] = 'Parameter file was successfully created.'
      redirect_to(tandem_parameter_files_url)
    else
      @tandem_parameter_file.tandem_modifications.each {|mod| mod.valid?}
      render :action => "new"
    end
  end

  # DELETE /tandem_parameter_file/1
  def destroy
    @tandem_parameter_file.destroy
    redirect_to(tandem_parameter_files_url)
  end

  protected
  
    def check_cancel
      redirect_to(tandem_parameter_files_url) and return if (params[:commit] == "cancel")
    end

    def load_tandem_parameter_file
      @tandem_parameter_file = TandemParameterFile.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to(tandem_parameter_files_url) and return
    end

end
