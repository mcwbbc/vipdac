namespace :node do

  desc "Download and formatdb the databases"
  task(:install_databases => :environment){ db = DatabaseInstaller.new; db.run  }
  
end