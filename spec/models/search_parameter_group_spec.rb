require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchParameterGroup do
  describe "connect" do
    it "should create the connection to SimpleDB and create the domain" do
      Aws.should_receive(:sdb).and_return("sdb")
      SearchParameterGroup.should_receive(:create_domain).and_return(true)
      SearchParameterGroup.connect
    end
  end

  describe "simpleDB methods" do
    before(:each) do
      SearchParameterGroup.should_receive(:connect)
    end

    ["xtandem", "omssa"].each do |searcher|
      it "should return all the records for #{searcher}" do
        SearchParameterGroup.should_receive(:find_all_by_searcher).with(searcher).and_return(["records"])
        SearchParameterGroup.all_for(searcher).should == ["records"]
      end

      it "should return the record for #{searcher} with the name" do
        Aws.should_receive(:encode).with("name").and_return("encoded")
        SearchParameterGroup.should_receive(:find_by_name_and_searcher).with("encoded", searcher).and_return("record")
        SearchParameterGroup.for_name_and_searcher("name", searcher).should == "record"
      end

      it "should create a new record associated with #{searcher}" do
        parameters = {"name"=>"am9ibmFtZQ==", "database"=>"aHVtYW5faXBp"}
        updated_parameters = {"name"=>"am9ibmFtZQ==", "database"=>"aHVtYW5faXBp", "searcher"=>"#{searcher}"}
        SearchParameterGroup.should_receive(:create).with(updated_parameters).and_return("record")
        SearchParameterGroup.new_for(parameters, searcher).should == "record"
      end
    end
  end

end
