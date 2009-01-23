namespace :head do

  desc "Import all the Omssa Parameter files from SimpleDB"
  task(:import_omssa => :environment){ OmssaParameterFile.import_from_simpledb  }

  desc "Import all the Tandem Parameter files from SimpleDB"
  task(:import_tandem => :environment){ TandemParameterFile.import_from_simpledb  }

  desc "Import all the search databases from SimpleDB"
  task(:import_search_databases => :environment){ SearchDatabase.import_from_simpledb  }
  
  desc "Insert all the default search databases from the search_databases.yml file"
  task(:insert_default_search_databases => :environment){ SearchDatabase.insert_default_databases  }
  
end