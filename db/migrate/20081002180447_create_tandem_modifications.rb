class CreateTandemModifications < ActiveRecord::Migration
  def self.up
    create_table :tandem_modifications do |t|
      t.integer :tandem_parameter_file_id
      t.float :mass
      t.string  :amino_acid
      t.timestamps
    end
  end

  def self.down
    drop_table :tandem_modifications
  end
end
