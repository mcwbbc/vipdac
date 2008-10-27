class CreateOmssaParameterFiles < ActiveRecord::Migration
  def self.up
    create_table :omssa_parameter_files do |t|
      t.string :name
      t.string :database
      t.integer :enzyme
      t.integer :missed_cleavages
      t.float :precursor_tol
      t.float :product_tol
      t.integer :precursor_search
      t.integer :product_search
      t.integer :minimum_charge
      t.integer :max_charge
      t.string :ions
      t.string :modifications

    end
  end

  def self.down
    drop_table :omssa_parameters_files
  end
end
