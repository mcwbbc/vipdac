class SearchDatabase < ActiveRecord::Base

  include Utilities
  extend Utilities
  
  before_destroy :remove_s3_files, :delete

  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :version, :message => "^Version file is required"
  validates_presence_of :db_type, :message => "^Database type is required"

  validates_uniqueness_of :version, :scope => :name

  has_attached_file :search_database, :path => ":rails_root/public/search_databases/:id_partition/:basename.:extension"
  validates_attachment_presence :search_database, :message => "^Search database file is required"
  validates_uniqueness_of :search_database_file_name
  validates_format_of :search_database_file_name, :with => /\.fasta$/, :message => "^Search database file isn't a fasta file"

  class << self
    # pagination
    def page(page=1, limit=15)
      paginate(:page => page,
               :order => 'name ASC',
               :per_page => limit
      )
    end

    def size_of(database_name)
      db = find(:first, :select => 'search_database_file_size', :conditions => ["search_database_file_name = ?", database_name])
      db ? db.search_database_file_size : 0
    end

    def import
      SearchDatabase.remote_database_array.each do |database|
        search_database = SearchDatabase.create(database)
      end
    end

    def remote_database_array
      files = SearchDatabase.remote_file_list("search-database-records")
      array = []
      files.each do |file|
        hash = YAML.load(SearchDatabase.retreive(file))
        hash.delete("filename")
        array << hash
      end
      array
    end

    def insert_default_databases
      databases = YAML.load_file(File.join(RAILS_ROOT, 'config', 'search_databases.yml'))
      databases.each do |database_hash|
        search_database = SearchDatabase.create(database_hash)
        search_database.persist
      end
    end

    def taxonomy_xml
      xml = ""
      databases = SearchDatabase.remote_database_array
      x = Builder::XmlMarkup.new(:target => xml, :indent=>2)
      x.instruct!
      x.bioml("label" => "x! taxon-to-file matching list") do
        databases.each do |database|
          file = database['search_database_file_name']
          x.taxon("label" => "#{file}") do
            x.file("format" => "peptide", "URL" => "/pipeline/dbs/#{file}")
          end
        end
      end
      xml
    end
      
    def write_taxonomy_file
      File.open("/pipeline/bin/tandem/taxonomy.xml", File::RDWR|File::CREAT) { |file| file.puts SearchDatabase.taxonomy_xml}
    end

    def available_for_search
      find(:all, :conditions => ["available = ?", true], :order => :name)
    end

    def select_options
      databases = SearchDatabase.available_for_search
      options = databases.map do |database|
        ["#{database.name} - #{database.version}", "#{database.search_database_file_name}"]
      end
    end

    def missing_on_node?(db)
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      on_node = true
      extensions.each do |extension|
        on_node = on_node && File.exists?("/pipeline/dbs/#{db}.#{extension}")
      end
      !on_node
    end

    def download_to_node(db)
      extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
      extensions.each do |extension|
        SearchDatabase.download_file("/pipeline/dbs/#{db}.#{extension}", "search-databases/#{db}.#{extension}")
      end
    end
  end

  def parameter_hash
    parameters = {}
    attributes.keys.each do |key|
      parameters["#{key}"] = "#{attributes[key]}"
    end
    parameters["filename"] = filename
    parameters.delete("id")
    parameters
  end

  def persist
    send_verified_data("search-database-records/#{md5_item(name, false)}.yml", parameter_hash.to_yaml, md5_item(parameter_hash.to_yaml, false), {})
  end

  def delete
    Aws.delete_object("search-database-records/#{md5_item(name, false)}.yml")
  end

  def process_and_upload
    run_reformat_db
    run_formatdb
    run_convert_databases
    upload_to_s3
    update_status_to_available
    persist
  end

  def remove_s3_files
    filenames.each do |file|
      Aws.delete_object("search-databases/#{file}")
    end
  end

  def upload_to_s3
    filenames.each do |file|
      send_file("search-databases/#{file}", "#{local_datafile_directory}#{file}")
    end
  end

  def filenames
    extensions = ["fasta", "phr", "pin", "psd", "psi", "psq", "r2a", "r2d", "r2s"]
    extensions.map { |e| "#{filename}.#{e}" }
  end

  def run_reformat_db
    if db_type == "ebi"
      db = self.search_database.path
      %x{cd #{local_datafile_directory} && perl /pipeline/vipdac/lib/reformat_db.pl #{db} #{db}-rev}
    end
  end

  def run_formatdb
    db = self.search_database.path
    input = (db_type == "ebi") ? "#{db}-rev" : db
    %x{cd #{local_datafile_directory} && /usr/local/bin/formatdb -i #{input} -o T -n #{filename}}
  end

  def run_convert_databases
    db = self.search_database.path
    %x{cd #{local_datafile_directory} && perl /pipeline/vipdac/lib/convert_databases.pl --input=#{db} --type=#{db_type}}
  end

  def send_background_process_message
    hash = {:type => PROCESSDATABASE, :database_id => id}
    MessageQueue.put(:name => 'head', :message => hash.to_yaml, :priority => 20, :ttr => 1200)
  end

  def filename
    data = /(.*)\.fasta$/i.match(search_database_file_name)
    data ? data[1] : ""
  end

  def update_status_to_available
    self.available = true
    self.save!
  end

  def local_datafile_directory
    File.join(RAILS_ROOT, "/public/search_databases/#{id_partition}/")
  end
  
  def id_partition
    ("%09d" % id).scan(/\d{3}/).join("/")
  end

end
