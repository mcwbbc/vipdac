class CreateSearchDatabases < ActiveRecord::Migration
  def self.up
    create_table :search_databases do |t|
      t.string :name
      t.string :version
      t.boolean :user_uploaded
      t.boolean :available
      t.string :search_database_file_name
      t.string :search_database_content_type
      t.integer :search_database_file_size
      t.datetime :search_database_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :search_databases
  end
end
