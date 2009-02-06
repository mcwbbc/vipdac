class CreateResultfiles < ActiveRecord::Migration
  def self.up
    create_table :resultfiles do |t|
      t.string :name
      t.string :link, :default => ""
      t.timestamps
    end
  end

  def self.down
    drop_table :resultfiles
  end
end
