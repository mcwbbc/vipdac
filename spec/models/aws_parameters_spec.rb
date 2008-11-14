require File.dirname(__FILE__) + '/../spec_helper'

describe AwsParameters do
  describe "get ec2 user data" do
    before(:each) do
      @uri = mock("uri")
      URI.should_receive(:parse).with("http://amazon-user-data.local/latest/user-data").and_return(@uri)
    end

    it "should return 'body' for a successful load" do
      @response = Net::HTTPSuccess.new(1, 200, "OK")
      @response.should_receive(:body).and_return("body")
      Net::HTTP.should_receive(:get_response).with(@uri).and_return(@response)
      AwsParameters.get_ec2_user_data.should == "body"
    end

    it "should return '' for a failed load" do
      response = mock("response")
      response.should_not_receive(:body)
      Net::HTTP.should_receive(:get_response).with(@uri).and_return(response)
      AwsParameters.get_ec2_user_data.should == ""
    end
  end
    
  describe "get ec2 meta" do

    describe "public-keys" do
      it "should return 'body' for a successful load adding a / to the key" do
        @uri = mock("uri")
        @key = "public-keys"
        URI.should_receive(:parse).with("http://amazon-user-data.local/latest/meta-data/#{@key}/").and_return(@uri)
        @response = Net::HTTPSuccess.new(1, 200, "OK")
        @response.should_receive(:body).and_return("body")
        Net::HTTP.should_receive(:get_response).with(@uri).and_return(@response)
        AwsParameters.get_ec2_meta_data(@key).should == "body"
      end
    end

    describe "regular keytype" do
      before(:each) do
        @uri = mock("uri")
        @key = "key"
        URI.should_receive(:parse).with("http://amazon-user-data.local/latest/meta-data/#{@key}").and_return(@uri)
      end

      it "should return 'body' for a successful load" do
        @response = Net::HTTPSuccess.new(1, 200, "OK")
        @response.should_receive(:body).and_return("body")
        Net::HTTP.should_receive(:get_response).with(@uri).and_return(@response)
        AwsParameters.get_ec2_meta_data(@key).should == "body"
      end

      it "should return '' for a failed load" do
        response = mock("response")
        response.should_not_receive(:body)
        Net::HTTP.should_receive(:get_response).with(@uri).and_return(response)
        AwsParameters.get_ec2_meta_data(@key).should == ""
      end
    end
  end
    
  it "should load yaml" do
    YAML.stub!(:load_file).and_return("yaml")
    AwsParameters.load_yaml.should  == "yaml"
  end

  describe "run" do
    before(:each) do
      Object.send(:remove_const, 'AwsParameters')
      load 'aws_parameters.rb'
      AwsParameters.should_receive(:get_ec2_user_data).and_return("hello=there,one=two")
      ['ami-id', 'instance-id', 'public-hostname', 'instance-type', 'local-hostname', 'local-ipv4', 'public-keys'].each do |md|
        AwsParameters.should_receive(:get_ec2_meta_data).with(md).and_return(md)
      end
      3.times {@config = AwsParameters.run}
    end

    it "should return information for all the meta data" do
      @config['hello'].should == 'there'
      @config['one'].should == 'two'
    end

    it "should include all the user data" do
      ['ami-id', 'instance-id', 'public-hostname', 'instance-type'].each do |md|
        @config[md].should == md
      end
    end

  end
  
end

