class ResultfilesController < ApplicationController

  before_filter :load_resultfile, :only => [:show, :destroy]

  # GET /resultfiles
  def index
    @page = params[:page] || 1
    @resultfiles = Resultfile.page(@page)
  end

  # GET /resultfiles/1
  def show
  end

  # DELETE /datafile/1
  def destroy
    @resultfile.destroy
    redirect_to(resultfiles_url)
  end

  protected
    def load_resultfile
      @resultfile = Resultfile.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to(resultfiles_url) and return
    end
end

