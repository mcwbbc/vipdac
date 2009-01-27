class NodesController < ApplicationController
  
#  before_filter :login_required
  before_filter :check_cancel, :only => [:create]
  before_filter :load_node, :only => [:show, :destroy]
  
  # GET /nodes
  def index
    @aws_nodes = Node.listing
    @active_nodes = Node.active_nodes
    @status_hash = Node.status_hash
    @nodes = Node.running
    @warning = (@active_nodes.size != @nodes.size)
  end

  # GET /nodes/1
  def show
    @aws_node = @node.describe
  end

  # GET /nodes/new
  def new
    @node = Node.new
    @launchable_nodes = Node.launchable_nodes
  end

  def aws
    @nodes = Node.listing
  end

  # POST /nodes
  def create
    @node = Node.new(params[:node])
    @quantity = params[:quantity]
    if @node.valid?
      1.upto(@quantity.to_i) do |i|
        @node = Node.new(params[:node])
        @node.launch
        @node.save
      end
      flash[:notice] = "#{@quantity} Node(s) were successfully launched."
      redirect_to(nodes_url)
    else
      @launchable_nodes = Node.launchable_nodes
      render :action => "new"
    end
  end

  # DELETE /nodes/1
  def destroy
    @node.remove_launched_instance
    @node.update_attribute(:active, false)
    redirect_to(nodes_url)
  end

  protected

    def load_node
      @node = Node.find_by_instance_id(params[:id])
      raise ActiveRecord::RecordNotFound if !@node

      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "That record id is not valid, you have been redirected."
        redirect_to nodes_url and return
    end

    def check_cancel
      redirect_to(nodes_url) and return if (params[:commit] == "cancel")
    end

end
