class Datafile < ActiveRecord::Base

  include Utilities
  extend Utilities
  
  before_destroy :remove_s3_files, :delete

  validates_presence_of :name, :message => "^Name is required"
  validates_uniqueness_of :name

  has_attached_file :uploaded, :path => ":rails_root/public/datafiles/:id_partition/:basename.:extension"
  validates_attachment_presence :uploaded, :message => "^Datafile is required"
  validates_uniqueness_of :uploaded_file_name
  validates_format_of :uploaded_file_name, :with => /\.mgf$/, :message => "^Datafile isn't an mgf file"

  class << self
    # pagination
    def page(page=1, limit=15)
      paginate(:page => page,
               :order => 'name ASC',
               :per_page => limit
      )
    end

    def import
      Datafile.remote_datafile_array.each do |database|
        datafile = Datafile.create(database)
      end
    end

    def remote_datafile_array
      files = Datafile.remote_file_list("datafile-records")
      array = []
      files.each do |file|
        hash = YAML.load(Datafile.retreive(file))
        hash.delete("filename")
        array << hash
      end
      array
    end

    def available_for_processing
      find(:all, :conditions => ["status = ?", "available"], :order => :name)
    end

    def select_options
      databases = Datafile.available_for_processing
      options = databases.map do |database|
        ["#{database.name}", "#{database.id}"]
      end
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
    send_verified_data("datafile-records/#{md5_item(name, false)}.yml", parameter_hash.to_yaml, md5_item(parameter_hash.to_yaml, false), {})
  end

  def delete
    Aws.delete_object("datafile-records/#{md5_item(name, false)}.yml")
  end

  def process_and_upload
    upload_to_s3
    update_status_to_available
    persist
  end

  def remove_s3_files
    Aws.delete_object("datafiles/#{uploaded_file_name}")
  end

  def upload_to_s3
    send_file("datafiles/#{uploaded_file_name}", "#{local_datafile_directory}#{uploaded_file_name}")
  end

  def send_background_process_message
    hash = {:type => PROCESSDATAFILE, :datafile_id => id}
    MessageQueue.put(:name => 'head', :message => hash.to_yaml, :priority => 20, :ttr => 1200)
  end

  def filename
    data = /(.*)\.mgf$/i.match(uploaded_file_name)
    data ? data[1] : ""
  end

  def update_status_to_available
    self.status = "Available"
    self.save!
  end

  def local_datafile_directory
    File.join(RAILS_ROOT, "/public/datafiles/#{id_partition}/")
  end
  
  def id_partition
    ("%09d" % id).scan(/\d{3}/).join("/")
  end

end
