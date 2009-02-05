class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.integer :parameter_file_id
      t.integer :datafile_id
      t.string :name
      t.string :status
      t.string :searcher
      t.string :hash_key
      t.string :link, :default => ""
      t.integer :spectra_count
      t.integer :priority
      t.float :launched_at, :limit => 53, :default => 0
      t.float :finished_at, :limit => 53, :default => 0
      t.float :started_pack_at, :limit => 53, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
