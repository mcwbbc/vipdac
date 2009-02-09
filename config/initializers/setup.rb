# Enable the will_paginate plugin
require 'will_paginate'

require 'constants'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'right_aws'
require 'right_http_connection'
require 'sdb/active_sdb'
require 'yaml'
require 'fileutils'
require 'utilities'
require 'digest/sha1'
require 'digest/md5'
require 'beanstalk-client'
require 'paperclip'
require 'hoptoad_notifier'

TOOL_VERSIONS = YAML::load_file( File.join(RAILS_ROOT, 'config', 'tool_versions.yml') ).freeze unless self.class.const_defined? "TOOL_VERSIONS"
