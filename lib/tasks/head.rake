namespace :head do

  desc "Import all the datafile records from S3"
  task(:import_datafiles => :environment) do
    begin
      Datafile.import
    rescue Exception => e
      puts e
    end
  end

  desc "Import all the Omssa Parameter files from S3"
  task(:import_omssa => :environment) do
    begin
      OmssaParameterFile.import
    rescue Exception => e
      puts e
    end
  end

  desc "Import all the Tandem Parameter files from S3"
  task(:import_tandem => :environment) do
    begin
      TandemParameterFile.import
    rescue Exception => e
      puts e
    end
  end

  desc "Import all the search databases from S3"
  task(:import_search_databases => :environment) do
    begin
      SearchDatabase.import
    rescue Exception => e
      puts e
    end
  end
  
  desc "Insert all the default search databases from the search_databases.yml file"
  task(:insert_default_search_databases => :environment) do
    begin
      SearchDatabase.insert_default_databases
    rescue Exception => e
      puts e
    end
  end
  
end