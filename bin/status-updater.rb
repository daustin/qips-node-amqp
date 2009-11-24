##########################
#
#   Imports state information from yml file
#   Adds other process information and sends it to rmgr. 
#   may kill and start node process of rmgr tells it to
# 
#   meant to be cronned
#
#

require 'rubygems'
require 'yaml'
require 'json'
require 'net/http'


STATUS_FILE = './tmp/status.yml'
STATUS_URL = 'http://localhost:3000/instance/set_status'
NODE_DAEMON_PATH = '/Users/daustin/git_repos/qips-node-amqp/bin/qips-node-amqp'
KILL_SIGNAL = 15

# Some of the more commonly used signals:
#     1       HUP (hang up)
#     2       INT (interrupt)
#     3       QUIT (quit)
#     6       ABRT (abort)
#     9       KILL (non-catchable, non-ignorable kill)
#     14      ALRM (alarm clock)
#     15      TERM (software termination signal)


unless File.size?(STATUS_FILE) then
  puts "YAML file not found or empty: #{STATUS_FILE}"
  exit 1  
end

yml_file = File.open(STATUS_FILE)

# first lets get the hash from the yaml file

yml_hash = YAML.load(yml_file)


# then we get process CPU
# for now lets just add a dummy CPU

yml_hash['system_cpu_usage'] = 0.11
yml_hash['ruby_cpu_usage'] = 0.22
yml_hash['system_mem_usage'] = 1234
yml_hash['ruby_mem_usage'] = 4321
yml_hash['top_pid'] = 5678
yml_hash['ruby_pid_status'] = "TEST"


# then we encode it to json and pass it back to the server

puts "Sending the following message to: #{STATUS_URL}"
puts yml_hash.to_json

kill = false

begin
  res = Net::HTTP.post_form(URI.parse(STATUS_URL),{'message'=> yml_hash.to_json})
  data = res.body
  kill = true if data =~ /.*KILL.*/

rescue Exception => e

  puts "HTTP error!  Could not update status!"
  puts e.message
end

if kill
  
  #First kill process, then start another one. 
  
  puts "KILL KILL KILL process: #{yml_hash['ruby_pid']}"
  
  Process.kill(KILL_SIGNAL, yml_hash['ruby_pid'].to_i)
  
  p1 = fork { system("ruby #{NODE_DAEMON_PATH}") }
  Process.detach(p1)
  
end







