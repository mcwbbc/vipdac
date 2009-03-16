class SearchDatabasesController < ApplicationController

  before_filter :check_cancel, :only => [:create, :update]
  before_filter :load_search_database, :only => [:show, :destroy]

  # GET /search_databases
  def index
    @page = params[:page] || 1
    @search_databases = SearchDatabase.page(@page)
  end

  # GET /search_databases/new
  def new
    @search_database = SearchDatabase.new
  end

  # POST /search_databases
  def create
    @search_database = SearchDatabase.new(params[:search_database])
    if @search_database.save
      @search_database.send_background_process_message
      flash[:notice] = 'SearchDatabase was successfully created.'
      redirect_to(search_databases_url)
    else
      render :action => "new"
    end
  end

  # DELETE /search_database/1
  def destroy
    @search_database.destroy
    redirect_to(search_databases_url)
  end

  protected
    def load_search_database
      @search_database = SearchDatabase.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to(search_databases_url) and return
    end

    def check_cancel
      redirect_to(search_databases_url) and return if (params[:commit] == "cancel")
    end
end
