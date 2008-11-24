class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.integer :parameter_file_id
      t.string :name
      t.string :status
      t.string :searcher
      t.string :datafile
      t.string :hash_key
      t.string :link, :default => ""
      t.integer :spectra_count
      t.integer :priority
      t.float :launched_at, :limit => 53, :default => 0
      t.float :finished_at, :limit => 53, :default => 0
      t.float :started_pack_at, :limit => 53, :default => 0
      t.string :mgf_file_name
      t.string :mgf_content_type
      t.integer :mgf_file_size
      t.datetime :mgf_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
