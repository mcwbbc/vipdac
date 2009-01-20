require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchDatabasesController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "search_databases", :action => "index").should == "/search_databases"
    end
  
    it "should map #new" do
      route_for(:controller => "search_databases", :action => "new").should == "/search_databases/new"
    end
  
    it "should map #show" do
      route_for(:controller => "search_databases", :action => "show", :id => 1).should == "/search_databases/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "search_databases", :action => "edit", :id => 1).should == "/search_databases/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "search_databases", :action => "update", :id => 1).should == "/search_databases/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "search_databases", :action => "destroy", :id => 1).should == "/search_databases/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/search_databases").should == {:controller => "search_databases", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/search_databases/new").should == {:controller => "search_databases", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/search_databases").should == {:controller => "search_databases", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/search_databases/1").should == {:controller => "search_databases", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/search_databases/1/edit").should == {:controller => "search_databases", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/search_databases/1").should == {:controller => "search_databases", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/search_databases/1").should == {:controller => "search_databases", :action => "destroy", :id => "1"}
    end
  end
end
