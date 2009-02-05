require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Datafile do
  before(:each) do
    @datafile = create_datafile
  end

  describe "create" do
    [:name].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_datafile(key => nil).should_not be_valid
      end
    end
  end

  describe "validations for" do
    describe "name" do
      it "should require a unique version for the name" do
        @datafile.save
        duplicate = create_datafile(:uploaded_file_name => "other.mgf")
        duplicate.should_not be_valid
        duplicate.should have(1).error_on(:name)
      end

      it "should require a unique version for the name" do
        @datafile.save
        duplicate = create_datafile(:name => "other", :uploaded_file_name => "other.mgf")
        duplicate.should be_valid
      end
    end

    describe "datafile file name" do
      it "should have an error with the same name" do
        @datafile.save
        duplicate = create_datafile(:name => "other")
        duplicate.should_not be_valid
        duplicate.should have(1).errors_on(:uploaded_file_name)
      end

      it "should be valid with a unique name" do
        @datafile.save
        duplicate = create_datafile(:name => "other", :uploaded_file_name => "other.mgf")
        duplicate.should be_valid
      end

      it "should be have a filename ending in .mgf" do
        database = create_datafile(:uploaded_file_name => "other")
        database.should have(1).error_on(:uploaded_file_name)
      end
    end
  end

  describe "send_background_upload_message" do
    it "should send a background upload head message" do
      @datafile.should_receive(:id).and_return(12)
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => PROCESSDATAFILE, :datafile_id => 12}.to_yaml, :priority => 20, :ttr => 1200).and_return(true)
      @datafile.send_background_process_message
    end
  end

  describe "available for processing" do
    it "should return an array of dbs that are available" do
      db = mock("db")
      Datafile.should_receive(:find).with(:all, :conditions => ["status = ?", "available"], :order => :name).and_return([db])
      Datafile.available_for_processing.should == [db]
    end
  end

  describe "page" do
    it "should call paginate" do
      Datafile.should_receive(:paginate).with({:page => 2, :order => 'name ASC', :per_page => 20}).and_return(true)
      Datafile.page(2,20)
    end
  end

  describe "import" do
    it "should create a local version of each of the databases in the array" do
      db = {'name' => 'dbname'}
      Datafile.should_receive(:remote_datafile_array).and_return([db])
      Datafile.should_receive(:create).with(db).and_return(true)
      Datafile.import
    end
  end

  describe "remote datafile array" do
    it "should build an array of all the available datafiles" do
      hash = {'filename' => 'file', 'name' => 'filename'}
      Datafile.should_receive(:remote_file_list).with("datafile-records").and_return(["file"])
      Datafile.should_receive(:retreive).with("file").and_return("string")
      YAML.should_receive(:load).with("string").and_return(hash)
      Datafile.remote_datafile_array.should == [{'name' => 'filename'}]
    end
  end

  describe "persist" do
    it "should send the yamlized parameters to s3" do
      @datafile.should_receive(:send_verified_data).with("datafile-records/6091de836f9094c2f45cee0aed9bb8ac.yml", "--- \nname: datafile_name\ncreated_at: 2009-01-10 12:00:00 UTC\nuploaded_content_type: text/plain\nupdated_at: 2009-01-10 12:00:00 UTC\nuploaded_updated_at: 2009-01-10 12:00:00 UTC\nuploaded_file_size: \"20\"\nuploaded_file_name: datafile_file.mgf\nstatus: available\n", "d57f0b1b999b8caeac31ae2412b6c410", {}).and_return(true)
      @datafile.persist
    end
  end

  describe "delete" do
    it "should remove the data file from s3" do
      Aws.should_receive(:delete_object).with("datafile-records/6091de836f9094c2f45cee0aed9bb8ac.yml").and_return(true)
      @datafile.delete
    end
  end

  describe "filename" do
    it "should return the datafile filename with .mgf stripped" do
      @datafile.filename.should == "datafile_file"
    end

    it "should return the '' if not a proper file" do
      @datafile.uploaded_file_name  = "other"
      @datafile.filename.should == ""
    end
  end

  describe "process and upload" do
    it "should run the steps to process and upload the database" do
      @datafile.should_receive(:upload_to_s3).ordered.and_return(true)
      @datafile.should_receive(:update_status_to_available).ordered.and_return(true)
      @datafile.should_receive(:persist).ordered.and_return(true)
      @datafile.process_and_upload
    end
  end

  describe "id partition" do
    it "should have an id partition for the id" do
      @datafile.id = 12
      @datafile.id_partition.should eql("000/000/012")
    end
  end

  describe "local datafile directory" do
    it "should return the local directory" do
      @datafile.id = 12
      @datafile.local_datafile_directory.should match(/\/public\/datafiles\/000\/000\/012\//)
    end
  end

  describe "update status" do
    it "should set the availablity to true and save" do
      @datafile.should_receive(:status=).with("Available").and_return(true)
      @datafile.should_receive(:save!).and_return(true)
      @datafile.update_status_to_available
    end
  end

  describe "upload converted databases to S3" do
    it "should send the data files to S3" do
      @datafile.should_receive(:send_file).with("datafiles/datafile_file.mgf", /datafile_file\.mgf/).and_return(true)
      @datafile.upload_to_s3.should be_true
    end
  end

  describe "remove S3 files on delete" do
    it "should remove the database files from S3 when deleted" do
      Aws.should_receive(:delete_object).with("datafiles/datafile_file.mgf").and_return(true)
      @datafile.remove_s3_files.should be_true
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      @datafile.parameter_hash.should == {"name"=>"datafile_name", "created_at"=>"2009-01-10 12:00:00 UTC", "uploaded_content_type"=>"text/plain", "updated_at"=>"2009-01-10 12:00:00 UTC", "uploaded_updated_at"=>"2009-01-10 12:00:00 UTC", "uploaded_file_size"=>"20", "uploaded_file_name"=>"datafile_file.mgf", "status"=>"available"}
    end
  end

  describe "search options" do
    it "should return an array of options for the datafile dropdowns" do
      db = mock("db")
      db.should_receive(:name).and_return("db")
      db.should_receive(:id).and_return(12)
      Datafile.should_receive(:available_for_processing).and_return([db])
      Datafile.select_options.should == [["db", "12"]]
    end
  end

  protected
    def create_datafile(options = {})
      record = Datafile.new({ :name => "datafile_name", :status => "available", :uploaded_file_name => 'datafile_file.mgf', :uploaded_content_type => 'text/plain', :uploaded_file_size => 20, :created_at => "2009-01-10 12:00:00", :updated_at => "2009-01-10 12:00:00", :uploaded_updated_at => "2009-01-10 12:00:00"}.merge(options))
      record
    end

end
