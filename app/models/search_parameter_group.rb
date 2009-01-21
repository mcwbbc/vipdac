class SearchParameterGroup < RightAws::ActiveSdb::Base

  class << self
    def connect
      sdb = Aws.sdb
      create_domain
    end

    def all_for(searcher)
      connect
      SearchParameterGroup.find_all_by_searcher(searcher)
    end

    def for_name_and_searcher(name, searcher)
      connect
      SearchParameterGroup.find_by_name_and_searcher(Aws.encode(name), searcher)
    end

    def new_for(parameters, searcher)
      connect
      parameters['searcher'] = searcher
      SearchParameterGroup.create(parameters)
    end
  end

end
