namespace :reporter do

  desc "Run the reporter/head listener"
  task(:run => :environment){ r = Reporter.new; r.run  }
  
end