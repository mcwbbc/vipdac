require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApplicationHelper
include TandemParameterFilesHelper

describe TandemParameterFilesHelper do

  describe "add_modification_link" do
    it "should return a link that adds a parameter modification" do
      @object = mock("object")
      TandemModification.should_receive(:new).and_return(@object)
      @page = mock("page")
      @page.should_receive(:insert_html).with(:bottom, :tandem_modifications, :partial=>"tandem_modification", :object => @object).and_return("link")
      should_receive(:link_to_function).with("hello").and_yield(@page)
      add_modification_link("hello").should == "link"
    end
  end

end
