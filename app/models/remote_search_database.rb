class RemoteSearchDatabase < RightAws::ActiveSdb::Base
  class << self
    def connect
      sdb = Aws.sdb
      create_domain
    end

    def all
      connect
      RemoteSearchDatabase.find(:all)
    end

    def all_default
      connect
      RemoteSearchDatabase.find(:all, :conditions => ["['user_uploaded'=?]", Aws.encode("false")])
    end

    def delete_default
      databases = RemoteSearchDatabase.all_default
      databases.each do |database|
        database.delete
      end
    end

    def for_filename(filename)
      connect
      RemoteSearchDatabase.find_by_filename(Aws.encode(filename))
    end

    def new_encode_for(parameters)
      encoded = RemoteSearchDatabase.encode_parameters(parameters)
      RemoteSearchDatabase.new_for(encoded)
    end

    def encode_parameters(hash)
      hash.keys.each { |key| hash[key] = Aws.encode("#{hash[key]}") }
      hash
    end

    def new_for(parameters)
      connect
      RemoteSearchDatabase.create(parameters)
    end
  end
end
