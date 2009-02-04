require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DatafilesController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "datafiles", :action => "index").should == "/datafiles"
    end
  
    it "should map #new" do
      route_for(:controller => "datafiles", :action => "new").should == "/datafiles/new"
    end
  
    it "should map #show" do
      route_for(:controller => "datafiles", :action => "show", :id => 1).should == "/datafiles/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "datafiles", :action => "edit", :id => 1).should == "/datafiles/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "datafiles", :action => "update", :id => 1).should == "/datafiles/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "datafiles", :action => "destroy", :id => 1).should == "/datafiles/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/datafiles").should == {:controller => "datafiles", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/datafiles/new").should == {:controller => "datafiles", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/datafiles").should == {:controller => "datafiles", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/datafiles/1").should == {:controller => "datafiles", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/datafiles/1/edit").should == {:controller => "datafiles", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/datafiles/1").should == {:controller => "datafiles", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/datafiles/1").should == {:controller => "datafiles", :action => "destroy", :id => "1"}
    end
  end
end
