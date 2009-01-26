class SearchDatabase < ActiveRecord::Base

  include Utilities

  before_destroy :remove_s3_files, :remove_from_simpledb

  validates_presence_of :name, :message => "^Name is required"
  validates_presence_of :version, :message => "^Version file is required"
  validates_presence_of :db_type, :message => "^Database type is required"

  validates_uniqueness_of :version, :scope => :name
  validates_uniqueness_of :search_database_file_name
  validates_uniqueness_of :search_database_file_name
  validates_format_of :search_database_file_name, :with => /\.fasta$/, :message => "^Search database file isn't a fasta file"

  has_attached_file :search_database, :path => ":rails_root/public/search_databases/:id_partition/:basename.:extension"
  validates_attachment_presence :search_database, :message => "^Search database file is required"

  class << self
    # pagination
    def page(page=1, limit=10)
      paginate(:page => page,
               :order => 'created_at DESC',
               :per_page => limit
      )
    end

    def import_from_simpledb
      records = RemoteSearchDatabase.all
      records.each do |record|
        record.reload
        parameter_file = SearchDatabase.new
        record.attributes.keys.each do |key|
          parameter_file["#{key}"] = Aws.decode(record["#{key}"])
        end
        parameter_file.save
      end
    end

    def insert_default_databases
      databases = YAML.load_file(File.join(RAILS_ROOT, 'config', 'search_databases.yml'))
      RemoteSearchDatabase.delete_default
      databases.each do |database_hash|
        search_database = SearchDatabase.create(database_hash)
        remote = RemoteSearchDatabase.new_encode_for(database_hash)
      end
    end

    def taxonomy_xml
      xml = ""
      records = RemoteSearchDatabase.all
      x = Builder::XmlMarkup.new(:target => xml, :indent=>2)
      x.instruct!
      x.bioml("label" => "x! taxon-to-file matching list") do
        records.each do |record|
          record.reload
          file = Aws.decode(record['search_database_file_name'])
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

  end

  def process_and_upload
    run_reformat_db
    run_formatdb
    run_convert_databases
    upload_to_s3
    update_status_to_available
    save_to_simpledb
  end

  def parameter_hash
    parameters = {}
    attributes.keys.each do |key|
      parameters["#{key}"] = Aws.encode("#{attributes[key]}")
    end
    parameters["filename"] = Aws.encode("#{filename}")
    parameters.delete("id")
    parameters
  end

  def save_to_simpledb
    RemoteSearchDatabase.new_for(parameter_hash)
  end

  def remove_from_simpledb
    record = RemoteSearchDatabase.for_filename(filename)
    record.delete if record
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
    MessageQueue.put(:name => 'head', :message => hash.to_yaml, :priority => 20, :ttr => 600)
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
