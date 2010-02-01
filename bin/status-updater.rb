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


STATUS_FILE = '/tmp/status.yml'
STATUS_URL = 'http://www-int.awsitmat.org/qips-rmgr-web/instance/set_status'
NODE_DAEMON_PATH = '/opt/qips-node-amqp/bin/qips-node-amqp'
KILL_SIGNAL = 15

# Some of the more commonly used signals:
#     1       HUP (hang up)
#     2       INT (interrupt)
#     3       QUIT (quit)
#     6       ABRT (abort)
#     9       KILL (non-catchable, non-ignorable kill)
#     14      ALRM (alarm clock)
#     15      TERM (software termination signal)


def send_status(yml_hash)
  begin
    res = Net::HTTP.post_form(URI.parse(STATUS_URL),{'message' => yml_hash.to_json})
    data = res.body
    kill = true if data =~ /.*KILL.*/

  rescue Exception => e

    puts "HTTP error!  Could not update status!"
    puts e.message
  end
end


unless File.size?(STATUS_FILE) then
  err_msg = "YAML file not found or empty: #{STATUS_FILE}"
  yml_hash = Hash.new
  yml_hash['state'] = 'error'
  yml_hash['error_message'] = err_msg
  send_status(yml_hash)
  exit 1  
end

yml_file = File.open(STATUS_FILE)

# first lets get the hash from the yaml file

yml_hash = YAML.load(yml_file)

send_status(yml_hash) if yml_hash['state'].eql?('error')

#System Memory Usage
sys_mem_free = `cat /proc/meminfo | grep MemFree | awk '{print $2}'`
sys_mem_total = `cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
yml_hash['system_mem_usage'] = (sys_mem_total.strip.to_f - sys_mem_free.strip.to_f)

daemon_status = `ps --no-headers -o pid,ppid,%cpu,%mem,stime,time,sz,rss,stat,user,command -p #{yml_hash['ruby_pid']}` 
stat_array = daemon_status.split(' ',11)

if (stat_array.nil? || stat_array.empty?)
  err_msg = "QIPS Node Daemon is not running"
  yml_hash['state'] = 'error'
  yml_hash['error_message'] = err_msg
  puts yml_hash.to_json
  send_status(yml_hash)
  exit 1
end

ppid = stat_array[1].strip()
yml_hash['ruby_cpu_usage'] = stat_array[2].strip
ruby_mem_percent = (stat_array[3].strip.to_f/100)
ruby_mem_usage = (sys_mem_total.to_f * ruby_mem_percent)
yml_hash['ruby_mem_usage'] = ruby_mem_usage
start_time = stat_array[4].strip
run_time = stat_array[5].strip
virt_mem = stat_array[6].strip
real_mem = stat_array[7].strip
stat_flag = stat_array[8].strip
proc_owner = stat_array[9].strip
command = stat_array[10].strip

#System CPU Usage
sys_cpu_stats = `w | grep average | awk '{print $8,$9,$10}'`
sys_cpu_stats_array = sys_cpu_stats.split(',')
yml_hash['system_cpu_usage'] = sys_cpu_stats_array[0]

#PID with highest CPU usage
top_cpu_str = `ps --no-header -eo pid --sort pcpu |tail -1`
yml_hash['top_pid'] = top_cpu_str.strip

#Ruby PID Status
ruby_pid_status = nil

stat_flag_array = stat_flag.strip.split(//)
case stat_flag_array[0]
  when 'D'
    ruby_pid_status = "Uninterruptible sleep"
  when 'R'
    ruby_pid_status = "Running or runnable"
  when 'S'
    ruby_pid_status = "Interruptible sleep"
  when 'T'
    ruby_pid_status = "Stopped, either by a job control signal or because it is being traced."
  when 'X'
    ruby_pid_status = "Dead"
  when 'Z'
    ruby_pid_status = "Zombie"
end

yml_hash['ruby_pid_status'] = ruby_pid_status

#Child process gathering

child_procs = `ps --no-headers -eo pid,ppid | grep #{yml_hash['ruby_pid']} | awk '{print $1}' | grep -iv #{yml_hash['ruby_pid']}`
child_proc_array = child_procs.split
yml_hash['child_procs'] = child_proc_array

# then we encode it to json and pass it back to the server

puts "Sending the following message to: #{STATUS_URL}"
puts yml_hash.to_json

kill = false

send_status(yml_hash)


if kill
  
  #First kill process, then start another one. 
  
  puts "KILL KILL KILL process: #{yml_hash['ruby_pid']}"
  
  Process.kill(KILL_SIGNAL, yml_hash['ruby_pid'].to_i)
  
  p1 = fork { system("ruby #{NODE_DAEMON_PATH}") }
  Process.detach(p1)
  
end







