#!/usr/bin/env ruby

# this script launches a watcher with listens to the node queue to process messages
# we launch it with an id, so we can run more than one per server

require 'rubygems'
require 'net/http'
require 'uri'
require 'yaml'
require 'right_aws'
require 'right_http_connection'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'fileutils'
require 'logger'
require 'beanstalk-client'

# load order is important
require '../app/models/constants'
require '../app/models/utilities'

require '../app/models/aws'
require '../app/models/aws_parameters'
require '../app/models/aws_message_queue'
require '../app/models/beanstalk_message_queue'
require '../app/models/message_queue'

require '../app/models/searcher'
require '../app/models/omssa'
require '../app/models/tandem'

require '../app/models/unpacker'
require '../app/models/packer'
require '../app/models/tandem_packer'
require '../app/models/omssa_packer'

require '../app/models/watcher'
require '../app/models/worker'
require '../app/models/node_runner'
require '../vendor/plugins/hoptoad_notifier/lib/hoptoad_notifier'
require '../config/initializers/hoptoad'

RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
RAILS_ENV = 'production'

  NodeRunner.run(ARGV)

exit(1)
