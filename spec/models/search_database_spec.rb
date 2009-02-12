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
        duplicate.should have(1).errors_on(:search_database_file_name)
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
      MessageQueue.should_receive(:put).with(:name => 'head', :message => {:type => PROCESSDATABASE, :database_id => 12}.to_yaml, :priority => 20, :ttr => 1200).and_return(true)
      @search_database.send_background_process_message
    end
  end

  describe "available for search" do
    it "should return an array of dbs that are available" do
      db = mock("db")
      SearchDatabase.should_receive(:find).with(:all, :conditions => ["available = ?", true], :order => :name).and_return([db])
      SearchDatabase.available_for_search.should == [db]
    end
  end

  describe "page" do
    it "should call paginate" do
      SearchDatabase.should_receive(:paginate).with({:page => 2, :order => 'name ASC', :per_page => 20}).and_return(true)
      SearchDatabase.page(2,20)
    end
  end

  describe "import" do
    it "should create a local version of each of the databases in the array" do
      db = {'name' => 'dbname'}
      SearchDatabase.should_receive(:remote_database_array).and_return([db])
      SearchDatabase.should_receive(:create).with(db).and_return(true)
      SearchDatabase.import
    end
  end

  describe "remote database array" do
    it "should build an array of all the available search databases" do
      hash = {'filename' => 'file', 'name' => 'dbname'}
      SearchDatabase.should_receive(:remote_file_list).with("search-database-records").and_return(["file"])
      SearchDatabase.should_receive(:retreive).with("file").and_return("string")
      YAML.should_receive(:load).with("string").and_return(hash)
      SearchDatabase.remote_database_array.should == [{'name' => 'dbname'}]
    end
  end

  describe "persist" do
    it "should send the yamlized parameters to s3" do
      @search_database.should_receive(:send_verified_data).with("search-database-records/ded71029ed304895d57098959b32ca9d.yml", "--- \nname: database_name\ncreated_at: 2009-01-10 12:00:00 UTC\navailable: \"false\"\nsearch_database_file_size: \"20\"\nupdated_at: 2009-01-10 12:00:00 UTC\nsearch_database_content_type: text/plain\nsearch_database_file_name: search_database_file.fasta\nsearch_database_updated_at: 2009-01-10 12:00:00 UTC\nversion: version\nfilename: search_database_file\ndb_type: ebi\nuser_uploaded: \"true\"\n", "472adfbc95187686fb4a7714b7306003", {}).and_return(true)
      @search_database.persist
    end
  end

  describe "delete" do
    it "should remove the data file from s3" do
      Aws.should_receive(:delete_object).with("search-database-records/ded71029ed304895d57098959b32ca9d.yml").and_return(true)
      @search_database.delete
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
      @search_database.should_receive(:persist).ordered.and_return(true)
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
      @database = mock("database")
      @database.should_receive(:persist).exactly(8).times.and_return(true)
      database_files = ["122.R_norvegicus.fasta", "18.E_coli_K12.fasta", "25.H_sapiens.fasta", "40.S_cerevisiae_ATCC_204508.fasta", "59.M_musculus.fasta", "ipi.HUMAN.v3.54.fasta", "ipi.MOUSE.v3.54.fasta", "ipi.RAT.v3.54.fasta"]
      database_files.each do |database|
        SearchDatabase.should_receive(:create).with(hash_including({:search_database_file_name => "#{database}"})).and_return(@database)
      end
      SearchDatabase.insert_default_databases
    end
  end

  describe "build taxonomy file" do
    it "should build the taxonomy file based on the available databases" do
      search_db = {"search_database_file_name" => "filename"}
      SearchDatabase.should_receive(:remote_database_array).and_return([search_db])
      xml = SearchDatabase.taxonomy_xml
      xml.should match(/label="filename"/)
      xml.should match(/URL="\/pipeline\/dbs\/filename"/)
    end
  end

  describe "write taxonomy file" do
    it "should write the taxonomy file to disk" do
      SearchDatabase.should_receive(:taxonomy_xml).and_return("xmldata")
      file = mock("file")
      file.should_receive(:puts).with("xmldata").and_return(true)
      File.should_receive(:open).with("/pipeline/bin/tandem/taxonomy.xml", File::RDWR|File::CREAT).and_yield(file)
      SearchDatabase.write_taxonomy_file
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      @search_database.parameter_hash.should == {"name"=>"database_name", "created_at"=>"2009-01-10 12:00:00 UTC", "available"=>"false", "search_database_file_size"=>"20", "updated_at"=>"2009-01-10 12:00:00 UTC", "search_database_content_type"=>"text/plain", "search_database_file_name"=>"search_database_file.fasta", "search_database_updated_at"=>"2009-01-10 12:00:00 UTC", "version"=>"version", "filename"=>"search_database_file", "db_type"=>"ebi", "user_uploaded"=>"true"}
    end
  end

  describe "missing on node?" do
    it "should return true if the db files aren't on the node" do
      File.should_receive(:exists?).with("/pipeline/dbs/database_name.fasta").and_return(false)
      SearchDatabase.missing_on_node?("database_name").should be_true
    end

    it "should return false if ALL the db files are on the node" do
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      extensions.each do |extension|
        File.should_receive(:exists?).with("/pipeline/dbs/database_name.#{extension}").and_return(true)
      end
      SearchDatabase.missing_on_node?("database_name").should be_false
    end
  end

  describe "download to node" do
    it "should download the database files to the node from S3" do
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      extensions.each do |extension|
        SearchDatabase.should_receive(:download_file).with("/pipeline/dbs/database_name.#{extension}", "search-databases/database_name.#{extension}").and_return(true)
      end
      SearchDatabase.download_to_node("database_name").should be_true
    end
  end

  describe "search options" do
    it "should return an array of options for the search database dropdowns" do
      db = mock("db")
      db.should_receive(:name).and_return("db")
      db.should_receive(:version).and_return("version")
      db.should_receive(:search_database_file_name).and_return("dbfilename")
      SearchDatabase.should_receive(:available_for_search).and_return([db])
      SearchDatabase.select_options.should == [["db - version", "dbfilename"]]
    end
  end

  protected
    def create_search_database(options = {})
      record = SearchDatabase.new({ :name => "database_name", :version => "version", :db_type => 'ebi', :user_uploaded => true, :available => false, :search_database_file_name => 'search_database_file.fasta', :search_database_content_type => 'text/plain', :search_database_file_size => 20, :created_at => "2009-01-10 12:00:00", :updated_at => "2009-01-10 12:00:00", :search_database_updated_at => "2009-01-10 12:00:00"}.merge(options))
      record
    end

end
