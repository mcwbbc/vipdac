  INSTANCES_ARRAY = [ ['Small', 'm1.small'],
                      ['Medium', 'c1.medium']
                    ].freeze unless self.class.const_defined? "INSTANCES_ARRAY"

  INSTANCES_HASH = INSTANCES_ARRAY.inject({}) do |result, element|
    result[element.last] = element.first
    result
  end.freeze unless self.class.const_defined? "INSTANCES_HASH"
  

  SEARCHER_ARRAY = [ ['OMSSA','omssa'],
                     ['Tandem','tandem']
                   ].freeze unless self.class.const_defined? "SEARCHER_ARRAY"

  SEARCHER_HASH = SEARCHER_ARRAY.inject({}) do |result, element|
     result[element.last] = element.first
     result
   end.freeze unless self.class.const_defined? "SEARCHER_HASH"

  PRIORITY_ARRAY = [ ['Low', 1000],
                     ['Medium', 500],
                     ['High', 200]
                   ].freeze unless self.class.const_defined? "PRIORITY_ARRAY"

  PRIORITY_HASH = PRIORITY_ARRAY.inject({}) do |result, element|
    result[element.last] = element.first
    result
  end.freeze unless self.class.const_defined? "PRIORITY_HASH"

  PIPELINE = '/pipeline'.freeze unless self.class.const_defined? "PIPELINE"

  PIPELINE_TMP = "/pipeline/tmp-#{$$}".freeze unless self.class.const_defined? "PIPELINE_TMP"
  UNPACK_DIR = "#{PIPELINE_TMP}/unpack".freeze unless self.class.const_defined? "UNPACK_DIR"
  PACK_DIR = "#{PIPELINE_TMP}/pack".freeze unless self.class.const_defined? "PACK_DIR"
  TANDEM_PATH = "/pipeline/bin/tandem".freeze unless self.class.const_defined? "TANDEM_PATH"
  OMSSA_PATH = "/pipeline/bin/omssa".freeze unless self.class.const_defined? "OMSSA_PATH"
  DB_PATH = "/pipeline/dbs".freeze unless self.class.const_defined? "DB_PATH"

  DB_BUCKET = 'pipeline-databases'.freeze unless self.class.const_defined? "DB_BUCKET"
  PARAMETER_FILENAME = "parameters.conf".freeze unless self.class.const_defined? "PARAMETER_FILENAME"

  LAUNCH = 'LAUNCH'.freeze unless self.class.const_defined? "LAUNCH"
  START = 'START'.freeze unless self.class.const_defined? "START"
  FINISH = 'FINISH'.freeze unless self.class.const_defined? "FINISH"
  CREATED = 'CREATED'.freeze unless self.class.const_defined? "CREATED"
  UNPACK = 'UNPACK'.freeze unless self.class.const_defined? "UNPACK"
  PROCESS = 'PROCESS'.freeze unless self.class.const_defined? "PROCESS"
  JOBUNPACKING = "JOBUNPACKING".freeze unless self.class.const_defined? "JOBUNPACKING"
  JOBUNPACKED = "JOBUNPACKED".freeze unless self.class.const_defined? "JOBUNPACKED"

  JOBPACKED = "JOBPACKED".freeze unless self.class.const_defined? "JOBPACKED"
  JOBPACKING = "JOBPACKING".freeze unless self.class.const_defined? "JOBPACKING"

  BACKGROUNDUPLOAD = "BACKGROUNDUPLOAD".freeze unless self.class.const_defined? "BACKGROUNDUPLOAD"

  PACK = "PACK".freeze unless self.class.const_defined? "PACK"
  FINISHED = "FINISHED".freeze unless self.class.const_defined? "FINISHED"

  SEARCHERS = ['omssa', 'tandem'].freeze unless self.class.const_defined? "SEARCHERS"
