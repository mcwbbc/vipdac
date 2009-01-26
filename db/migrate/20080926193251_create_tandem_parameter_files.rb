class CreateTandemParameterFiles < ActiveRecord::Migration
  def self.up
    create_table :tandem_parameter_files do |t|
      t.string :name
      t.string :database
      t.string :enzyme
      t.boolean :a_ion
      t.boolean :b_ion
      t.boolean :c_ion
      t.boolean :x_ion
      t.boolean :y_ion
      t.boolean :z_ion
      t.float :n_terminal
      t.float :c_terminal
      t.timestamps
    end
  end

  def self.down
    drop_table :tandem_parameter_files
  end
end
