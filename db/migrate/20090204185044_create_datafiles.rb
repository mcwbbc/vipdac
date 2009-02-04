class CreateDatafiles < ActiveRecord::Migration
  def self.up
    create_table :datafiles do |t|
      t.string :name
      t.string :status
      t.string :uploaded_file_name
      t.string :uploaded_content_type
      t.integer :uploaded_file_size
      t.datetime :uploaded_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :datafiles
  end
end

