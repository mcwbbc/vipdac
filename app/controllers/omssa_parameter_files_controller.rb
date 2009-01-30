class OmssaParameterFilesController < ApplicationController

  before_filter :check_cancel, :only => [:create, :update]
  before_filter :load_omssa_parameter_file, :only => [:show, :destroy]

  # GET /omssa_parameter_files
  def index
    @page = params[:page] || 1
    @omssa_parameter_files = OmssaParameterFile.page(@page)
  end

  # GET /omssa_parameter_files/1
  def show
  end

  # GET /omssa_parameter_files/new
  def new
    @omssa_parameter_file = OmssaParameterFile.new( :ions => '1,4', 
                                                    :enzyme => 0, 
                                                    :precursor_tol => 2.5, 
                                                    :product_tol => 0.8,
                                                    :minimum_charge => 2,
                                                    :max_charge => 3,
                                                    :missed_cleavages => 0 )
  end

  # POST /omssa_parameter_files
  def create
    @omssa_parameter_file = OmssaParameterFile.new(params[:omssa_parameter_file])

    @omssa_parameter_file.ions = (0..5).inject([]) {|a,i| a << params["ion#{i}".to_sym] unless params["ion#{i}".to_sym] == nil; a}.join(',')
    
    if @omssa_parameter_file.save
      @omssa_parameter_file.persist
      flash[:notice] = 'Omssa Parameter File was successfully created.'
      redirect_to(omssa_parameter_files_url)
    else
      render :action => "new"
    end
  end

  # DELETE /omssa_parameter_files/1
  def destroy
    @omssa_parameter_file.destroy
    redirect_to(omssa_parameter_files_url)
  end

  protected
  
    def check_cancel
      redirect_to(omssa_parameter_files_url) and return if (params[:commit] == "cancel")
    end

    def load_omssa_parameter_file
      @omssa_parameter_file = OmssaParameterFile.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to(omssa_parameter_files_url) and return
    end

end
