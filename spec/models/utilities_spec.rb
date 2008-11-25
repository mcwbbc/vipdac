require File.dirname(__FILE__) + '/../spec_helper'

describe Utilities do

  describe "md5 item" do
    before(:each) do
      @fake = FakeClass.new
    end

    describe "incremental" do
      it "should description" do
        @line = "Hello World"
        @file = mock_model(File)
        @file.should_receive(:each_line).and_yield(@line)
        File.should_receive(:open).with("filename", 'r').and_return(@file)
        @fake.md5_item("filename").should == "b10a8db164e0754105b7a99be72e3fe5"
      end
    end

    describe "single shot" do
      it "should return an md5 sum" do
        @fake.md5_item("Hello World", false).should == "b10a8db164e0754105b7a99be72e3fe5"
      end
    end
  end

  describe "download file" do
    before(:each) do
      @fake = FakeClass.new
    end

    it "should create a new file" do
      @hash = mock("hash")
      @chunk = mock("chunk")
      @s3i = mock("s3interface")
      @s3i.should_receive(:get).with("bucket", "remote").and_yield(@chunk).and_return(@hash)
      @file = mock_model(File)
      @file.should_receive(:write).with(@chunk).and_return(true)
      @file.should_receive(:close).and_return(true)
      Aws.should_receive(:bucket_name).and_return("bucket")
      Aws.should_receive(:s3i).and_return(@s3i)
      File.should_receive(:new).with("local", File::CREAT|File::RDWR ).and_return(@file)
      @fake.download_file("local", "remote").should == @hash
    end
  end

  describe "send verified data" do
    before(:each) do
      @fake = FakeClass.new
    end

    describe "with exception" do
      describe "with failed md5" do
        it "should retry" do
          @hash = {"date"=>"Mon, 29 Sep 2008 18:38:32 GMT", :verified_md5=>true, "content-length"=>"0"}
          @exception = RightAws::AwsError.new
          @exception.should_receive(:message).and_return("Uploaded object failed MD5 checksum verification")
          Aws.should_receive(:put_verified_object).ordered.with("key", "data", "md5", {}).and_raise(@exception)
          @fake.send_verified_data("key", "data", "md5", {})
        end
      end

      describe "with other Aws exception" do
        it "should continue raising" do
          Aws.should_receive(:put_verified_object).with("key", "data", "md5", {}).and_raise(RightAws::AwsError)
          lambda { @fake.send_verified_data("key", "data", "md5", {}) }.should raise_error(RightAws::AwsError)
        end
      end

      describe "with other exception" do
        it "should continue raising" do
          Aws.should_receive(:put_verified_object).with("key", "data", "md5", {}).and_raise(Exception)
          lambda { @fake.send_verified_data("key", "data", "md5", {}) }.should raise_error(Exception)
        end
      end
    end

    describe "without exception" do
      it "should return the hash including verified_md5 = true" do
        @hash = {"date"=>"Mon, 29 Sep 2008 18:38:32 GMT", :verified_md5=>true, "content-length"=>"0"}
        Aws.should_receive(:put_verified_object).with("key", "data", "md5", {}).and_return(@hash)
        @fake.send_verified_data("key", "data", "md5", {})[:verified_md5].should be_true
      end
    end

  end

  describe "send file" do
    before(:each) do
      @fake = FakeClass.new
    end

    it "should return true if file uploaded" do
      @file = mock_model(File)
      File.should_receive(:open).with("local").and_yield(@file)
      @fake.should_receive(:md5_item).with("local").and_return("abcd")
      @fake.should_receive(:send_verified_data).with("remote", @file, "abcd", {"x-amz-acl" => "public-read"}).and_return(true)
      @fake.send_file("remote", "local").should be_true
    end
  end

  describe "remove item" do
    before(:each) do
      @fake = FakeClass.new
    end

    it "should remove the pack directory" do
      File.should_receive(:exists?).and_return(true)
      FileUtils.should_receive(:rm_r).and_return(true)
      @fake.remove_item("dir")
    end

    it "should not remove the pack directory" do
      File.should_receive(:exists?).and_return(false)
      FileUtils.should_not_receive(:rm_r).and_return(true)
      @fake.remove_item("dir")
    end
  end

  describe "unzip file" do
    before(:each) do
      @fake = FakeClass.new
    end

    it "should unzip the zip file into the target" do
      entry = "entry"
      dir = mock("dir")
      dir.should_receive(:entries).with('.').and_return([entry])
      zipfile = mock("zipfile")
      zipfile.should_receive(:dir).and_return(dir)
      zipfile.should_receive(:extract).with("entry", "target/entry").and_return(true)
      Zip::ZipFile.should_receive(:open).with("source").and_yield(zipfile)
      @fake.unzip_file("source", "target")
    end

    it "should return nil for an exception" do
      Zip::ZipFile.should_receive(:open).with("source").and_raise(Zip::ZipDestinationFileExistsError)
      @fake.unzip_file("source", "target").should be_nil
    end
  end

  describe "make directory" do
    before(:each) do
      @fake = FakeClass.new
    end

    describe "with existing" do
      it "should not create it" do
        File.should_receive(:exists?).with("cheese").and_return(true)
        Dir.should_not_receive(:mkdir)
        @fake.make_directory("cheese")
      end
    end
    describe "without existing" do
      it "should create it" do
        File.should_receive(:exists?).with("cheese").and_return(false)
        Dir.should_receive(:mkdir).with("cheese").and_return(true)
        @fake.make_directory("cheese")
      end
    end
  end

  describe "input file should spilt string on /" do
    before(:each) do
      @fake = FakeClass.new
    end

    it "should return nil for single string" do
      @fake.input_file("/").should be_nil
    end

    it "should return last with one /" do
      @fake.input_file("/last").should == "last"
    end

    it "should return last element" do
      @fake.input_file("/hello/there/last").should == "last"
    end
  end

  describe "ignore?" do
    before(:each) do
      @fake = FakeClass.new
    end

    describe "with ignored error" do
      before(:each) do
        @exception = SignalException.new("TERM")
      end
      it "should be true as class" do
        HoptoadNotifier.should_receive(:ignore).and_return([SignalException])
        @fake.ignore?(@exception).should be_true
      end
      it "should be true as string" do
        HoptoadNotifier.should_receive(:ignore).and_return(['SignalException'])
        @fake.ignore?(@exception).should be_true
      end
    end
    describe "with regular errror" do
      before(:each) do
        @exception = Exception.new
      end

      it "should be false as class" do
        HoptoadNotifier.should_receive(:ignore).and_return([SignalException])
        @fake.ignore?(@exception).should be_false
      end
      it "should be false as string" do
        HoptoadNotifier.should_receive(:ignore).and_return(['SignalException'])
        @fake.ignore?(@exception).should be_false
      end
    end
  end

  class FakeClass
    include Utilities
  end

end
