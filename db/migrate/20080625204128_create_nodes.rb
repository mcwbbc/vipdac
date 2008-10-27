class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :instance_type
      t.string :instance_id
      t.boolean :active, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
