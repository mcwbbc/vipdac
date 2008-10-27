class NodesController < ApplicationController
  
#  before_filter :login_required
  before_filter :check_cancel, :only => [:create]
  before_filter :load_node, :only => [:show, :destroy]
  
  # GET /nodes
  def index
    @aws_nodes = Node.listing
    @active_nodes = Node.active_nodes
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
  end

  def aws
    @nodes = Node.listing
  end

  # POST /nodes
  def create
    @node = Node.new(params[:node])
    if @node.valid?
      @node.launch
      @node.save
      flash[:notice] = 'Node was successfully launched.'
      redirect_to(nodes_url)
    else
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
