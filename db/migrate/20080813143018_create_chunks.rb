class CreateChunks < ActiveRecord::Migration
  def self.up
    create_table :chunks do |t|
      t.integer :job_id
      t.string :chunk_key
      t.string :instance_id
      t.string :instance_size
      t.string :filename
      t.string :parameter_filename
      t.integer :bytes
      t.integer :chunk_count, :default => 0
      t.float :sent_at, :limit => 53, :default => 0
      t.float :started_at, :limit => 53, :default => 0
      t.float :finished_at, :limit => 53, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :chunks
  end
end
