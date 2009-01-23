class SearchDatabase < ActiveRecord::Base

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
  end

  def send_background_process_message
    hash = {:type => PROCESSDATABASE, :database_id => id}
    MessageQueue.put(:name => 'head', :message => hash.to_yaml, :priority => 20, :ttr => 600)
  end

  def filename
    data = /(.*)\.fasta$/i.match(search_database_file_name)
    data ? data[1] : ""
  end

end
