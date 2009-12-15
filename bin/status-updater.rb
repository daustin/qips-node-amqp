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

daemon_proc = `ps -ef | grep -i qips-node-amqp | awk '{print $2}'`
daemon_status = `ps --no-headers -o pid,ppid,%cpu,%mem,stime,time,sz,rss,stat,user,command -p #{daemon_proc}` 
stat_array = status.split(' ',11)

yml_hash['ruby_pid'] = stat_array[0].strip
ppid = stat_array[1].strip
yml_hash['ruby_cpu_usage'] = stat_array[2].strip
yml_hash['ruby_mem_usage'] = stat_array[3].strip
start_time = stat_array[4].strip
run_time = stat_array[5].strip
virt_mem = stat_array[6].strip
real_mem = stat_array[7].strip
stat_flag = stat_array[8].strip
proc_owner = stat_array[9].strip
command = stat_array[10].strip

#System CPU Usage
sys_cpu_stats = `w | awk '{print $11,$12,$13}'`
sys_cpu_stats_array = sys_cpu_stats.split(',')
yml_hash['system_cpu_usage'] = sys_cpu_stat_array[0]

#System Memory Usage
sys_mem_free = `cat /proc/meminfo | grep MemFree | awk '{print $2}'`
sys_mem_total = `cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
yml_hash['system_mem_usage'] = (sys_mem_total.strip.to_i - sys_mem_free.strip.to_i)

#PID with highest CPU usage
top_cpu_str = `ps -eo pid | sort -k 1 -r | head -1`
yml_hash['top_pid'] = top_cpu_str.strip

#Ruby PID Status
ruby_pid_status = nil

switch (stat_flag.strip) {
  case D:
    ruby_pid_status = "Uninterruptible sleep"
    break;
  case R:
    ruby_pid_status = "Running or runnable"
    break;
  case S:
    ruby_pid_status = "Interruptible sleep"
    break;
  case T:
    ruby_pid_status = "Stopped, either by a job control signal or because it is being traced."
    break;
  case X:
    ruby_pid_status = "Dead"
    break;
  case Z:
    ruby_pid_status = "Zombie"
    break;
}

yml_hash['ruby_pid_status'] = ruby_pid_status

#yml_hash['system_cpu_usage'] = 0.11
#yml_hash['ruby_cpu_usage'] = 0.22
#yml_hash['system_mem_usage'] = 1234
#yml_hash['ruby_mem_usage'] = 4321
#yml_hash['top_pid'] = 5678
#yml_hash['ruby_pid_status'] = "TEST"


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







