# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090206153711) do

  create_table "chunks", :force => true do |t|
    t.integer  "job_id"
    t.string   "chunk_key"
    t.string   "instance_id"
    t.string   "instance_size",      :limit => 20
    t.string   "filename"
    t.string   "parameter_filename"
    t.integer  "bytes"
    t.integer  "chunk_count",                      :default => 0
    t.float    "sent_at",                          :default => 0.0
    t.float    "started_at",                       :default => 0.0
    t.float    "finished_at",                      :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datafiles", :force => true do |t|
    t.string   "name"
    t.string   "status"
    t.string   "uploaded_file_name"
    t.string   "uploaded_content_type"
    t.integer  "uploaded_file_size"
    t.datetime "uploaded_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.integer  "parameter_file_id"
    t.integer  "datafile_id"
    t.string   "name"
    t.string   "status"
    t.string   "searcher"
    t.string   "hash_key"
    t.string   "link",              :default => ""
    t.integer  "spectra_count"
    t.integer  "priority"
    t.float    "launched_at",       :default => 0.0
    t.float    "finished_at",       :default => 0.0
    t.float    "started_pack_at",   :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nodes", :force => true do |t|
    t.string   "instance_type"
    t.string   "instance_id"
    t.boolean  "active",        :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omssa_parameter_files", :force => true do |t|
    t.string  "name"
    t.string  "database"
    t.integer "enzyme"
    t.integer "missed_cleavages"
    t.float   "precursor_tol"
    t.float   "product_tol"
    t.integer "precursor_search"
    t.integer "product_search"
    t.integer "minimum_charge"
    t.integer "max_charge"
    t.string  "ions"
    t.string  "modifications"
  end

  create_table "resultfiles", :force => true do |t|
    t.string   "name"
    t.string   "link",       :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_databases", :force => true do |t|
    t.string   "name"
    t.string   "version"
    t.string   "db_type"
    t.boolean  "user_uploaded"
    t.boolean  "available"
    t.string   "search_database_file_name"
    t.string   "search_database_content_type"
    t.integer  "search_database_file_size"
    t.datetime "search_database_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tandem_modifications", :force => true do |t|
    t.integer  "tandem_parameter_file_id"
    t.float    "mass"
    t.string   "amino_acid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tandem_parameter_files", :force => true do |t|
    t.string   "name"
    t.string   "database"
    t.string   "enzyme"
    t.boolean  "a_ion"
    t.boolean  "b_ion"
    t.boolean  "c_ion"
    t.boolean  "x_ion"
    t.boolean  "y_ion"
    t.boolean  "z_ion"
    t.float    "n_terminal"
    t.float    "c_terminal"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
