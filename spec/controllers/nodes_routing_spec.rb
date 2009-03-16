require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NodesController do
  describe "route generation" do

    it "should map { :controller => 'nodes', :action => 'index' } to /nodes" do
      route_for(:controller => "nodes", :action => "index").should == "/nodes"
    end
  
    it "should map { :controller => 'nodes', :action => 'new' } to /nodes/new" do
      route_for(:controller => "nodes", :action => "new").should == "/nodes/new"
    end
  
    it "should map { :controller => 'nodes', :action => 'show', :id => 1 } to /nodes/1" do
      route_for(:controller => "nodes", :action => "show", :id => '1').should == "/nodes/1"
    end
  
    it "should map { :controller => 'nodes', :action => 'edit', :id => 1 } to /nodes/1/edit" do
      route_for(:controller => "nodes", :action => "edit", :id => '1').should == "/nodes/1/edit"
    end
  
    it "should map { :controller => 'nodes', :action => 'update', :id => 1} to /nodes/1" do
      route_for(:controller => "nodes", :action => "update", :id => '1').should == {:path => "/nodes/1", :method => :put}
    end
  
    it "should map { :controller => 'nodes', :action => 'destroy', :id => 1} to /nodes/1" do
      route_for(:controller => "nodes", :action => "destroy", :id => '1').should == {:path => "/nodes/1", :method => :delete}
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'nodes', action => 'index' } from GET /nodes" do
      params_from(:get, "/nodes").should == {:controller => "nodes", :action => "index"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'new' } from GET /nodes/new" do
      params_from(:get, "/nodes/new").should == {:controller => "nodes", :action => "new"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'create' } from POST /nodes" do
      params_from(:post, "/nodes").should == {:controller => "nodes", :action => "create"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'show', id => '1' } from GET /nodes/1" do
      params_from(:get, "/nodes/1").should == {:controller => "nodes", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'edit', id => '1' } from GET /nodes/1;edit" do
      params_from(:get, "/nodes/1/edit").should == {:controller => "nodes", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'update', id => '1' } from PUT /nodes/1" do
      params_from(:put, "/nodes/1").should == {:controller => "nodes", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'nodes', action => 'destroy', id => '1' } from DELETE /nodes/1" do
      params_from(:delete, "/nodes/1").should == {:controller => "nodes", :action => "destroy", :id => "1"}
    end
  end
end
