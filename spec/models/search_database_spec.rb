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

  describe "process and upload" do
    it "should run the steps to process and upload the database" do
      @search_database.should_receive(:run_reformat_db).ordered.and_return(true)
      @search_database.should_receive(:run_formatdb).ordered.and_return(true)
      @search_database.should_receive(:run_convert_databases).ordered.and_return(true)
      @search_database.should_receive(:upload_to_s3).ordered.and_return(true)
      @search_database.should_receive(:update_status_to_available).ordered.and_return(true)
      @search_database.should_receive(:save_to_simpledb).ordered.and_return(true)
      @search_database.process_and_upload
    end
  end

  describe "id partition" do
    it "should have an id partition for the id" do
      @search_database.id = 12
      @search_database.id_partition.should eql("000/000/012")
    end
  end

  describe "local datafile directory" do
    it "should return the local directory" do
      @search_database.id = 12
      @search_database.local_datafile_directory.should match(/\/public\/search_databases\/000\/000\/012\//)
    end
  end

  describe "update status" do
    it "should set the availablity to true and save" do
      @search_database.should_receive(:available=).with(true).and_return(true)
      @search_database.should_receive(:save!).and_return(true)
      @search_database.update_status_to_available
    end
  end

  describe "run_reformat_db" do
    it "should run the reformat_db.pl script if we have an ebi type db" do
      @search_database.should_receive(:`).with(/^cd \/.* && .*\/reformat_db\.pl/).and_return(true)
      @search_database.run_reformat_db.should be_true
    end

    it "should not run the reformat_db.pl script for non ebi type db" do
      @search_database.db_type = "ipi"
      @search_database.run_reformat_db.should be_nil
    end
  end

  describe "formatdb database" do
    it "should run formatdb on the reformatted database as other" do
      @search_database.db_type = "ipi"
      @search_database.should_receive(:`).with(/^cd \/.* && .*\/formatdb.*search_database_file\.fasta -o T -n search_database_file/).and_return(true)
      @search_database.run_formatdb.should be_true
    end

    it "should run formatdb on the reformatted database as ebi" do
      @search_database.should_receive(:`).with(/^cd \/.* && .*\/formatdb.*search_database_file\.fasta-rev -o T -n search_database_file/).and_return(true)
      @search_database.run_formatdb.should be_true
    end
  end

  describe "convert databases" do
    it "should run convert_database.pl for use with the ez2 processing scripts as ebi" do
      @search_database.should_receive(:`).with(/^cd \/.* && .*\/convert_databases\.pl --input=.*\/search_database_file\.fasta --type=ebi/).and_return(true)
      @search_database.run_convert_databases.should be_true
    end

    it "should run convert_database.pl for use with the ez2 processing scripts as ipi" do
      @search_database.db_type = "ipi"
      @search_database.should_receive(:`).with(/^cd \/.* && .*\/convert_databases\.pl --input=.*\/search_database_file\.fasta --type=ipi/).and_return(true)
      @search_database.run_convert_databases.should be_true
    end
  end

  describe "upload converted databases to S3" do
    it "should send the data files to S3" do
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      extensions.each do |extension|
        @search_database.should_receive(:send_file).with("search-databases/search_database_file.#{extension}", /search_database_file\.#{extension}/).and_return(true)
      end
      @search_database.upload_to_s3.should be_true
    end
  end

  describe "database filenames" do
    it "should return an array of the filenames required for the database" do
      @search_database.filenames.should == ["search_database_file.fasta", "search_database_file.phr", "search_database_file.pin", "search_database_file.psd", "search_database_file.psi", "search_database_file.psq", "search_database_file.r2a", "search_database_file.r2d", "search_database_file.r2s"]
    end
  end

  describe "remove S3 files on delete" do
    it "should remove the database files from S3 when deleted" do
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      extensions.each do |extension|
        Aws.should_receive(:delete_object).with("search-databases/search_database_file.#{extension}").and_return(true)
      end
      @search_database.remove_s3_files.should be_true
    end
  end

  describe "insert default databases" do
    it "should read in the yaml file and insert the default databases" do
      database_files = ["122.R_norvegicus.fasta", "18.E_coli_K12.fasta", "25.H_sapiens.fasta", "40.S_cerevisiae_ATCC_204508.fasta", "59.M_musculus.fasta", "ipi.HUMAN.v3.54.fasta", "ipi.MOUSE.v3.54.fasta", "ipi.RAT.v3.54.fasta", "orf_trans.fasta"]
      database_files.each do |database|
        SearchDatabase.should_receive(:create).with(hash_including({:search_database_file_name => "#{database}"})).and_return(true)
      end
      SearchDatabase.insert_default_databases
    end
  end

  describe "build taxonomy file" do
    it "should build the taxonomy file based on the available databases"
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      @search_database.parameter_hash.should == {"name"=>"ZGF0YWJhc2VfbmFtZQ==", "created_at"=>"MjAwOS0wMS0xMCAxMjowMDowMCBVVEM=", "available"=>"ZmFsc2U=", "search_database_file_size"=>"MjA=", "updated_at"=>"MjAwOS0wMS0xMCAxMjowMDowMCBVVEM=", "search_database_content_type"=>"dGV4dC9wbGFpbg==", "search_database_file_name"=>"c2VhcmNoX2RhdGFiYXNlX2ZpbGUuZmFzdGE=", "search_database_updated_at"=>"MjAwOS0wMS0xMCAxMjowMDowMCBVVEM=", "version"=>"dmVyc2lvbg==", "filename"=>"c2VhcmNoX2RhdGFiYXNlX2ZpbGU=", "db_type"=>"ZWJp", "user_uploaded"=>"dHJ1ZQ=="}
    end
  end

  describe "import from simpledb" do
    it "should import the databases from simpleDB" do
      @sd = SearchDatabase.new
      @rsd = mock_model(RemoteSearchDatabase)
      @rsd.should_receive(:reload).and_return(true)
      attributes = mock("hash")
      attributes.should_receive(:keys).and_return(['name', 'created_at', 'available', 'search_database_file_size', 'updated_at', 'search_database_content_type', 'search_database_file_name', 'search_database_updated_at', 'version', 'filename', 'db_type', 'user_uploaded'])
      @rsd.should_receive(:attributes).and_return(attributes)
      @rsd.should_receive(:[]).with('name').and_return(["ZGF0YWJhc2VfbmFtZQ=="])
      @rsd.should_receive(:[]).with('created_at').and_return(["MjAwOS0wMS0xMCAxMjowMDowMCBVVEM="])
      @rsd.should_receive(:[]).with('available').and_return(["ZmFsc2U="])
      @rsd.should_receive(:[]).with('search_database_file_size').and_return(["MjA="])
      @rsd.should_receive(:[]).with('updated_at').and_return(["MjAwOS0wMS0xMCAxMjowMDowMCBVVEM="])
      @rsd.should_receive(:[]).with('search_database_content_type').and_return(["dGV4dC9wbGFpbg=="])
      @rsd.should_receive(:[]).with('search_database_file_name').and_return(["c2VhcmNoX2RhdGFiYXNlX2ZpbGUuZmFzdGE="])
      @rsd.should_receive(:[]).with('search_database_updated_at').and_return(["MjAwOS0wMS0xMCAxMjowMDowMCBVVEM="])
      @rsd.should_receive(:[]).with('version').and_return(["dmVyc2lvbg=="])
      @rsd.should_receive(:[]).with('filename').and_return(["c2VhcmNoX2RhdGFiYXNlX2ZpbGU="])
      @rsd.should_receive(:[]).with('db_type').and_return(["ZWJp"])
      @rsd.should_receive(:[]).with('user_uploaded').and_return(["dHJ1ZQ=="])
      RemoteSearchDatabase.should_receive(:all).and_return([@rsd])
      @sd.should_receive(:[]=).with("name", "database_name").and_return(true)
      @sd.should_receive(:[]=).with("created_at", "2009-01-10 12:00:00 UTC").and_return(true)
      @sd.should_receive(:[]=).with("available", "false").and_return(true)
      @sd.should_receive(:[]=).with("search_database_file_size", "20").and_return(true)
      @sd.should_receive(:[]=).with("updated_at", "2009-01-10 12:00:00 UTC").and_return(true)
      @sd.should_receive(:[]=).with("search_database_content_type", "text/plain").and_return(true)
      @sd.should_receive(:[]=).with("search_database_file_name", "search_database_file.fasta").and_return(true)
      @sd.should_receive(:[]=).with("search_database_updated_at", "2009-01-10 12:00:00 UTC").and_return(true)
      @sd.should_receive(:[]=).with("version", "version").and_return(true)
      @sd.should_receive(:[]=).with("filename", "search_database_file").and_return(true)
      @sd.should_receive(:[]=).with("db_type", "ebi").and_return(true)
      @sd.should_receive(:[]=).with("user_uploaded", "true").and_return(true)
      SearchDatabase.should_receive(:new).and_return(@sd)
      @sd.should_receive(:save).and_return(true)
      SearchDatabase.import_from_simpledb
    end
  end

  describe "save to simple db" do
    it "should save the encoded parameters to simpledb" do
      @search_database.should_receive(:parameter_hash).and_return({:hash => true})
      RemoteSearchDatabase.should_receive(:new_for).with({:hash => true}).and_return(true)
      @search_database.save_to_simpledb
    end
  end

  describe "remove from simpledb" do
    it "should remove the record from simpledb" do
      record = mock("simpledb_record")
      record.should_receive(:delete).and_return(true)
      RemoteSearchDatabase.should_receive(:for_filename).with("search_database_file").and_return(record)
      @search_database.remove_from_simpledb
    end

    it "should do nothing if the record isn't in simpledb" do
      RemoteSearchDatabase.should_receive(:for_filename).with("search_database_file").and_return(nil)
      @search_database.remove_from_simpledb
    end
  end

  protected
    def create_search_database(options = {})
      record = SearchDatabase.new({ :name => "database_name", :version => "version", :db_type => 'ebi', :user_uploaded => true, :available => false, :search_database_file_name => 'search_database_file.fasta', :search_database_content_type => 'text/plain', :search_database_file_size => 20, :created_at => "2009-01-10 12:00:00", :updated_at => "2009-01-10 12:00:00", :search_database_updated_at => "2009-01-10 12:00:00"}.merge(options))
      record
    end

end
