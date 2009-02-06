require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResultfilesController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "resultfiles", :action => "index").should == "/resultfiles"
    end
  
    it "should map #new" do
      route_for(:controller => "resultfiles", :action => "new").should == "/resultfiles/new"
    end
  
    it "should map #show" do
      route_for(:controller => "resultfiles", :action => "show", :id => 1).should == "/resultfiles/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "resultfiles", :action => "edit", :id => 1).should == "/resultfiles/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "resultfiles", :action => "update", :id => 1).should == "/resultfiles/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "resultfiles", :action => "destroy", :id => 1).should == "/resultfiles/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/resultfiles").should == {:controller => "resultfiles", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/resultfiles/new").should == {:controller => "resultfiles", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/resultfiles").should == {:controller => "resultfiles", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/resultfiles/1").should == {:controller => "resultfiles", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/resultfiles/1/edit").should == {:controller => "resultfiles", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/resultfiles/1").should == {:controller => "resultfiles", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/resultfiles/1").should == {:controller => "resultfiles", :action => "destroy", :id => "1"}
    end
  end
end
