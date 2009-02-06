require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resultfile do
  before(:each) do
    @resultfile = create_resultfile
  end

  describe "create" do
    [:name].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_resultfile(key => nil).should_not be_valid
      end
    end
  end

  describe "page" do
    it "should call paginate" do
      Resultfile.should_receive(:paginate).with({:page => 2, :order => 'name ASC', :per_page => 20}).and_return(true)
      Resultfile.page(2,20)
    end
  end

  describe "import" do
    it "should create a local version of each of the databases in the array" do
      db = {'name' => 'dbname'}
      Resultfile.should_receive(:remote_resultfile_array).and_return([db])
      Resultfile.should_receive(:create).with(db).and_return(true)
      Resultfile.import
    end
  end

  describe "remote resultfile array" do
    it "should build an array of all the available resultfiles" do
      hash = {'filename' => 'file', 'name' => 'filename'}
      Resultfile.should_receive(:remote_file_list).with("resultfile-records").and_return(["file"])
      Resultfile.should_receive(:retreive).with("file").and_return("string")
      YAML.should_receive(:load).with("string").and_return(hash)
      Resultfile.remote_resultfile_array.should == [{'name' => 'filename'}]
    end
  end

  describe "persist" do
    it "should send the yamlized parameters to s3" do
      @resultfile.should_receive(:send_verified_data).with("resultfile-records/86471e826a5620684cf36107713056a4.yml", "--- \nname: resultfile_name\ncreated_at: 2009-01-10 12:00:00 UTC\nupdated_at: 2009-01-10 12:00:00 UTC\nlink: http://link\n", "56d0048a78be15a3d34b4b43582ca042", {}).and_return(true)
      @resultfile.persist
    end
  end

  describe "delete" do
    it "should remove the data file from s3" do
      Aws.should_receive(:delete_object).with("resultfile-records/86471e826a5620684cf36107713056a4.yml").and_return(true)
      @resultfile.delete
    end
  end

  describe "remove S3 files on delete" do
    it "should remove the database files from S3 when deleted" do
      Aws.should_receive(:delete_object).with("resultfiles/resultfile_name.zip").and_return(true)
      @resultfile.remove_s3_files.should be_true
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      @resultfile.parameter_hash.should == {"name"=>"resultfile_name", "link"=>"http://link", "created_at"=>"2009-01-10 12:00:00 UTC", "updated_at"=>"2009-01-10 12:00:00 UTC"}
    end
  end

  protected
    def create_resultfile(options = {})
      record = Resultfile.new({ :name => "resultfile_name", :link => "http://link", :created_at => "2009-01-10 12:00:00", :updated_at => "2009-01-10 12:00:00"}.merge(options))
      record
    end
end
