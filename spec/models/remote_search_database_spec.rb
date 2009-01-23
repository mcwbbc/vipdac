require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RemoteSearchDatabase do
  describe "connect" do
    it "should create the connection to SimpleDB and create the domain" do
      Aws.should_receive(:sdb).and_return("sdb")
      RemoteSearchDatabase.should_receive(:create_domain).and_return(true)
      RemoteSearchDatabase.connect
    end
  end

  describe "simpleDB methods" do
    before(:each) do
      RemoteSearchDatabase.should_receive(:connect)
    end

    it "should return all the records" do
      RemoteSearchDatabase.should_receive(:find).with(:all).and_return(["records"])
      RemoteSearchDatabase.all.should == ["records"]
    end

    it "should return the record with the search_database_file_name" do
      Aws.should_receive(:encode).with("filename").and_return("encoded")
      RemoteSearchDatabase.should_receive(:find_by_filename).with("encoded").and_return("record")
      RemoteSearchDatabase.for_filename("filename").should == "record"
    end

    it "should create a new record" do
      parameters = {"name"=>"am9ibmFtZQ==", "filename"=>"aHVtYW5faXBp"}
      RemoteSearchDatabase.should_receive(:create).with(parameters).and_return("record")
      RemoteSearchDatabase.new_for(parameters).should == "record"
    end
  end
end
