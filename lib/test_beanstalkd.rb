#!/usr/bin/env ruby

require 'rubygems'
require 'beanstalk-client'

DEFAULT_PORT = 11300
SERVER_IP = '127.0.0.1'
#beanstalk will order the queues based on priority, with the same priority
#it acts FIFO, in a later example we will use the priority
#(higher numbers are higher priority)
DEFAULT_PRIORITY = 65536
#TTR is time for the job to reappear on the queue.
#Assuming a worker died before completing work and never called job.delete
#the same job would return back on the queue (in seconds)
TTR = 3

class BeanBase

  #To work with multiple queues you must tell beanstalk which queues
  #you plan on writing to (use), and which queues you will reserve jobs from
  #(watch). In this case we also want to ignore the default queue
  def get_queue(queue_name)
    queue = Beanstalk::Pool.new(["#{SERVER_IP}:#{DEFAULT_PORT}"])
    queue.watch(queue_name)
    queue.use(queue_name)
    queue.ignore('default')
    queue
  end

end

class BeanDistributor < BeanBase

  def initialize(amount)
    @messages = amount
  end

  def start_distributor
    #put all the work on the request queue
    bean_queue = get_queue('requests')
    @messages.times do |num|
      msg = BeanRequest.new(1,num)
      #Take our ruby object and convert it to yml and put it on the queue
      bean_queue.yput(msg,pri=DEFAULT_PRIORITY, delay=0, ttr=TTR)
    end

    puts "distributor now getting results"
    #get all the results from the results queue
    bean_queue = get_queue('results')
    @messages.times do |num|
      result = take_msg(bean_queue)
      puts "result: #{result}"
    end

  end

  #this will take a message off the queue, process it and return the result
  def take_msg(queue)
    msg = queue.reserve
    #by calling ybody we get the content of the message and convert it from yml
    count = msg.ybody.count
    msg.delete
    return count
  end

end

class BeanWorker < BeanBase

  def initialize(amount)
    @messages = amount
    @received_msgs = 0
  end

  def start_worker
    results = []
    #get and process all the requests, on the requests queue
    bean_queue = get_queue('requests')
    @messages.times do |num|
      result = take_msg(bean_queue)
      results << result
      @received_msgs += 1
    end

    #return all of the results, by placing them on the separate results queue
    bean_queue = get_queue('results')
    results.each do |result|
      msg = BeanResult.new(1,result)
      bean_queue.yput(msg,pri=DEFAULT_PRIORITY, delay=0, ttr=TTR)
    end

    #this is just to pass information out of the forked process
    #we return the number of messages we received as our exit status
    exit @received_msgs
  end

  #this will take a message off the queue, process it and return the result
  def take_msg(queue)
    msg = queue.reserve
    #by calling ybody we get the content of the message and convert it from yml
    count = msg.ybody.count
    result = count*count
    msg.delete
    return result
  end

end

############
# These are just simple message classes that we pass using beanstalks
# to yml and from yml functions.
############
class BeanRequest
  attr_accessor :project_id, :count
  def initialize(project_id, count=0)
    @project_id = project_id
    @count = count
  end
end

class BeanResult
  attr_accessor :project_id, :count
  def initialize(project_id, count=0)
    @project_id = project_id
    @count = count
  end
end

#write X messages on the queue
numb = 10

recv_count = 0

# Most of the time you will have two entirely seperate classes
# but to make it easy to run this example we will just fork and start our server
# and client seperately. We will wait for them to complete and check
# if we received all the messages we expected.
puts "starting distributor"
server_pid = fork {
  BeanDistributor.new(numb).start_distributor
}

puts "starting client"
client_pid = fork {
  BeanWorker.new(numb).start_worker
}

Process.wait(client_pid)
recv_count = $?.exitstatus
puts "client finished received #{recv_count} msgs"
if(numb==recv_count)
  puts "received the expected number of messages"
else
  puts "error didn't receive the correct number of messages"
end

Process.wait(server_pid)
