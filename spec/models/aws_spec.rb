require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Aws do
  before(:each) do
    Object.send(:remove_const, 'Aws')
    load 'aws.rb'
  end

  describe "keys" do
    it "should return the values from AwsParameters" do
      AwsParameters.should_receive(:run).and_return("keys")
      Aws.keys.should == "keys"
    end
  end

  describe "encode" do
    it "should encode the data into base 64" do
      Aws.encode("hello").should == "aGVsbG8="
    end

    it "should return nil if there is no data" do
      Aws.encode(nil).should be_nil
    end
  end

  describe "decode" do
    it "should encode the data into base 64" do
      Aws.decode(["aGVsbG8="]).should == "hello"
    end

    it "should return nil if there is no data" do
      Aws.decode(nil).should be_nil
    end
  end

  describe "s3 actions" do
    before(:each) do
      @s3 = mock("s3")
      Aws.stub!(:s3i).and_return(@s3)
      Aws.should_receive(:bucket_name).and_return("bucket")
    end

    it "should put an object on s3" do
      @s3.should_receive(:put).with("bucket", "object","data",{})
      Aws.put_object("object", "data")
    end

    it "should put an object on s3 verifying the md5" do
      hash = {"x-amz-id-2"=>"IZN3XsH4FlBU0+XYkFTfHwaiF1tNzrm6dIW2EM/cthKvl71nldfVC0oVQyydzWpb", "content-length"=>"0"}
      @s3.should_receive(:store_object_and_verify).with(:bucket => "bucket", :key => "object", :md5 => "md5", :data => "data", :headers => {}).and_return(hash)
      Aws.put_verified_object("object", "data", "md5").should == hash
    end

    it "should get an object from s3" do
      @s3.should_receive(:get_object).with("bucket", "object")
      Aws.get_object("object")
    end

    it "should delete a folder from s3" do
      @s3.should_receive(:delete_folder).with("bucket", "object")
      Aws.delete_folder("object")
    end

    it "should delete an object from s3" do
      @s3.should_receive(:delete_folder).with("bucket", "object")
      Aws.delete_object("object")
    end

    it "should create a bucket" do
      @s3.should_receive(:create_bucket).with("bucket").and_return(true)
      Aws.create_bucket.should be_true
    end

  end

  describe "create interfaces" do
    before(:each) do
      Aws.should_receive(:keys).twice.and_return({'aws_access' => 'access', 'aws_secret' => 'secret'})
    end

    it "should create an ec2 interface" do
      RightAws::Ec2.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.ec2.should == "interface"
    end

    it "should create an sqs interface" do
      RightAws::SqsGen2.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.sqs.should == "interface"
    end

    it "should create an s3i interface" do
      RightAws::S3Interface.should_receive(:new).with("access", "secret").and_return("interface")
      Aws.s3i.should == "interface"
    end

    it "should create an sdb interface" do
      RightAws::ActiveSdb.should_receive(:establish_connection).with("access", "secret").and_return("interface")
      Aws.sdb.should == "interface"
    end
  end

  describe "with mocks" do
    before(:each) do
      @s3i = mock("s3i")
      @ec2 = mock("ec2")

      Aws.stub!(:ec2).and_return(@ec2)
      Aws.stub!(:s3i).and_return(@s3i)
      Aws.stub!(:keys).and_return({'aws_access' => 'access', 'aws_secret' => 'secret', 'public-hostname' => 'hostname',
                                   'instance-id' => 'instance-id', 'instance-type' => 'instance-type', 'ami-id' => 'ami-1234',
                                   'local-hostname' => 'local-hostname', 'local-ipv4' => 'local-ipv4', 'public-keys' => '0=ec2-keypair'})
    end
    describe "current hostname" do
      it "should be 'test' for test environment" do
        Aws.current_hostname.should == "test"
      end

      it "should be the public hostname key" do
        Aws.current_hostname.should == "test"
      end
    end

    describe "access_key" do
      it "should be the aws access key" do
        Aws.access_key.should == "access"
      end
    end

    describe "secret_key" do
      it "should be the aws secret key" do
        Aws.secret_key.should == "secret"
      end
    end

    describe "instance id" do
      it "should be the instance id key" do
        Aws.instance_id.should == "instance-id"
      end
    end

    describe "instance type" do
      it "should be the instance type" do
        Aws.instance_type.should == "instance-type"
      end
    end

    describe "local-hostname" do
      it "should be the local-hostname" do
        Aws.local_hostname.should == "local-hostname"
      end
    end

    describe "local-ipv4" do
      it "should be the local-ipv4" do
        Aws.local_ipv4.should == "local-ipv4"
      end
    end

    describe "public-keys" do
      it "should be the public-keys" do
        Aws.public_keys.should == "0=ec2-keypair"
      end
    end

    describe "ami-id" do
      it "should be the ami-id" do
        Aws.ami_id.should == "ami-1234"
      end
    end

    describe "keypairs" do
      it "should return an empty array for an exception" do
        @ec2.should_receive(:describe_key_pairs).and_throw(Exception)
        Aws.keypairs.should == []
      end
      it "should return an array of hashes" do
        @ec2.should_receive(:describe_key_pairs).and_return([{:aws_fingerprint=> "01:02", :aws_key_name=>"key-1"}])
        Aws.keypairs.should == [{:aws_fingerprint=> "01:02", :aws_key_name=>"key-1"}]
      end
    end

    describe "keypair" do
      it "should be the keypair name if it exists" do
        Aws.stub!(:keypairs).and_return([{:aws_fingerprint=> "01:02", :aws_key_name=>"key-1"}])
        Aws.keypair.should == "key-1"
      end

      it "should be blank for nil" do
        Aws.stub!(:keypairs).and_return([])
        Aws.keypair.should be_nil
      end
    end

    describe "amis" do
      it "should return an ami for i386 with id ami-12345" do
        Aws.stub!(:ami_id).and_return("ami-12345")
        Aws.amis.should == {'i386' => 'ami-12345'}
      end
    end

    describe "workers" do
      it "should return a number of wokers based on the instance type" do
        Aws.workers("m1.small").should == 1
        Aws.workers("c1.medium").should == 1
      end
    end
  end

  describe "folder name" do
    it "should return nil for a missing key" do
      Aws.stub!(:keys).and_return({})
      Aws.folder.should be_nil
    end

    it "should remove non-number/letters" do
      Aws.stub!(:keys).and_return({'folder' => 'user_folder'})
      Aws.folder.should == "userfolder"
    end

    it "should downcase" do
      Aws.stub!(:keys).and_return({'folder' => 'USERFOLDER'})
      Aws.folder.should == "userfolder"
    end

    it "should remove spaces" do
      Aws.stub!(:keys).and_return({'folder' => 'user fold er'})
      Aws.folder.should == "userfolder"
    end
  end

  describe "bucket name" do
    describe "default" do
      it "should be the access key" do
        Aws.stub!(:keys).and_return({'aws_access' => 'access'})
        Aws.bucket_name.should == "access-vipdac"
      end
    end

    describe "with user data as bucketname" do
      it "should prefix the bucket name with the userdata" do
        Aws.stub!(:keys).and_return({'aws_access' => 'access', 'folder' => 'userfolder'})
        Aws.bucket_name.should == "userfolder-access-vipdac"
      end
    end
  end

end
