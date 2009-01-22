require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApplicationHelper
include SearchDatabasesHelper

describe SearchDatabasesHelper do

  describe "is_available?" do
    it "should return 'Available' if it is" do
      db = mock("db", :available? => true)
      is_available?(db).should == "Available"
    end

    it "should return 'Processing' if it isn't" do
      db = mock("db", :available? => false)
      is_available?(db).should == "Processing"
    end
  end

end

