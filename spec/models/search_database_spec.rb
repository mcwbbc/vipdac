require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchDatabase do
  before(:each) do
    @search_database = create_search_database
  end

  describe "create" do
    [:name, :version, :db_type].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_search_database(key => nil).should_not be_valid
      end
    end
  end

  describe "validations for" do
    describe "version" do
      it "should require a unique version for the name" do
        @search_database.save
        duplicate = create_search_database(:search_database_file_name => "other.fasta")
        duplicate.should_not be_valid
        duplicate.should have(1).error_on(:version)
      end

      it "should require a unique version for the name" do
        @search_database.save
        duplicate = create_search_database(:name => "other", :search_database_file_name => "other.fasta")
        duplicate.should be_valid
      end
    end

    describe "search database file name" do
      it "should have an error with the same name" do
        @search_database.save
        duplicate = create_search_database(:name => "other")
        duplicate.should_not be_valid
        duplicate.should have(2).errors_on(:search_database_file_name)
      end

      it "should be valid with a unique name" do
        @search_database.save
        duplicate = create_search_database(:name => "other", :search_database_file_name => "other.fasta")
        duplicate.should be_valid
      end

      it "should be have a filename ending in .fasta" do
        database = create_search_database(:search_database_file_name => "other")
        database.should have(1).error_on(:search_database_file_name)
      end
    end
  end

  describe "send_background_upload_message" do
    it "should send a background upload head message" do
      @search_database.should_receive(:id).and_return(12)
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => PROCESSDATABASE, :database_id => 12}.to_yaml, :priority => 20, :ttr => 600).and_return(true)
      @search_database.send_background_process_message
    end
  end

  describe "page" do
    it "should call paginate" do
      SearchDatabase.should_receive(:paginate).with({:page => 2, :order => 'created_at DESC', :per_page => 20}).and_return(true)
      SearchDatabase.page(2,20)
    end
  end

  describe "filename" do
    it "should return the search database filename with .fasta stripped" do
      @search_database.filename.should == "search_database_file"
    end

    it "should return the '' if not a proper file" do
      @search_database.search_database_file_name  = "other"
      @search_database.filename.should == ""
    end
  end

  describe "reformat database" do
    it "should reformat the UniProt header line"
  end

  describe "formatdb database" do
    it "should run formatdb on the database"
  end

  describe "convert database" do
    it "should convert the database for use with the ez2 processing scripts"
  end

  describe "upload converted databases to S3" do
    it "should send the data to S3"
  end

  describe "create simpleDB entry" do
    it "should create a record in simpleDB for the database"
  end

  describe "remove S3 files on delete" do
    it "should remove the database files from S3 when deleted"
  end

  describe "remove simpleDB entry" do
    it "should remove the simpleDB record when deleted"
  end

  describe "find user databases" do
    it "should return a list of all user databases from simpleDB"
  end

  describe "build taxonomy file" do
    it "should build the taxonomy file based on the available databases"
  end

  protected
    def create_search_database(options = {})
      record = SearchDatabase.new({ :name => "database_name", :version => "version", :user_uploaded => true, :available => false, :search_database_file_name => 'search_database_file.fasta', :search_database_content_type => 'text/plain', :search_database_file_size => 20 }.merge(options))
      record
    end

end
