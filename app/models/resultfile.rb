class Resultfile < ActiveRecord::Base

  include Utilities
  extend Utilities
  
  before_destroy :remove_s3_files, :delete

  validates_presence_of :name, :message => "^Name is required"

  class << self
    # pagination
    def page(page=1, limit=15)
      paginate(:page => page,
               :order => 'name ASC',
               :per_page => limit
      )
    end

    def import
      Resultfile.remote_resultfile_array.each do |database|
        resultfile = Resultfile.create(database)
      end
    end

    def remote_resultfile_array
      files = Resultfile.remote_file_list("resultfile-records")
      array = []
      files.each do |file|
        hash = YAML.load(Resultfile.retreive(file))
        hash.delete("filename")
        array << hash
      end
      array
    end
  end

  def parameter_hash
    parameters = {}
    attributes.keys.each do |key|
      parameters["#{key}"] = "#{attributes[key]}"
    end
    parameters.delete("id")
    parameters
  end

  def persist
    send_verified_data("resultfile-records/#{md5_item(name, false)}.yml", parameter_hash.to_yaml, md5_item(parameter_hash.to_yaml, false), {})
  end

  def delete
    Aws.delete_object("resultfile-records/#{md5_item(name, false)}.yml")
  end

  def remove_s3_files
    Aws.delete_object("resultfiles/#{name}.zip")
  end
end
