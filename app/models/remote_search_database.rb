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

    def for_filename(filename)
      connect
      RemoteSearchDatabase.find_by_filename(Aws.encode(filename))
    end

    def new_for(parameters)
      connect
      RemoteSearchDatabase.create(parameters)
    end
  end
end
