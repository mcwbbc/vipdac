#!/usr/bin/env ruby

dir = File.expand_path(File.join(File.dirname(__FILE__),'..'))

unless($LOAD_PATH.member?(dir))
  $LOAD_PATH.unshift(dir)
end

require 'rubygems'
require 'yaml'
require 'ruby-debug'
require 'beanstalk-client'

def id
  '127.0.0.1:11300'
end

def get_client
  Beanstalk::Pool.new(id)
end

def list_queues
  client = get_client
  puts client.raw_stats.pretty_inspect
  puts "current-connections: #{client.stats['current-connections']}"
  queues = client.list_tubes
  queues[id].each do |queue_name|
    stats = client.stats_tube(queue_name)
    puts queue_name + " ... watch: #{stats['current-watching']}, use: #{stats['current-using']}" 
  end
end

def queue_stats(queue_name)
  puts get_client.stats_tube(queue_name).to_yaml
end

# Should add a flag to use this method instead of queue_stats
def add_message(queue_name)
  client = get_client
  client.watch(queue_name)
  client.use(queue_name)
  client.yput("message")
end

queue_name = ARGV.shift
if(queue_name.nil?)
  list_queues
else
  #add_message(queue_name)
  queue_stats(queue_name)
end

