module SearchDatabasesHelper

  def is_available?(database)
    database.available? ? "Available" : "Processing"
  end

end
