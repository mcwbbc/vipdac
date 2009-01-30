namespace :head do

  desc "Import all the Omssa Parameter files from SimpleDB"
  task(:import_omssa => :environment) do
    begin
      OmssaParameterFile.import
    rescue Exception => e
      puts e
    end
  end

  desc "Import all the Tandem Parameter files from SimpleDB"
  task(:import_tandem => :environment) do
    begin
      TandemParameterFile.import_from_simpledb
    rescue Exception => e
      puts e
    end
  end

  desc "Import all the search databases from SimpleDB"
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