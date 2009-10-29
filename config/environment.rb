# Be sure to restart your daemon when you modify this file

# Uncomment below to force your daemon into production mode
#ENV['DAEMON_ENV'] ||= 'production'

# NOTE: set listen queue(s) in ruote.yml

# this is the uri for the node to send state updates to rmgr:
# will add /instance-id?state=idle&timeout=2009...
STATUS_URL = 'http://localhost:3000/instance/set_state'

# meta url is where node looks to get it's instance ID
META_URL = 'http://169.254.169.254/latest/meta-data/instance-id'

# this is the instance_id to use when not an AWS instance
ALT_INSTANCE_ID = 'i-abcd1234'

# working directory. this is where all the work's done on this node
WORK_DIR = '/Users/daustin/scratch'

#get AWS creds for s3
require File.join(File.dirname(__FILE__), 'aws')

# Boot up
require File.join(File.dirname(__FILE__), 'boot')

DaemonKit::Initializer.run do |config|

  # The name of the daemon as reported by process monitoring tools
  config.daemon_name = 'qips-node-amqp'

  # Force the daemon to be killed after X seconds from asking it to
  # config.force_kill_wait = 30

  # Log backraces when a thread/daemon dies (Recommended)
  # config.backtraces = true

  # Configure the safety net (see DaemonKit::Safety)
  # config.safety_net.handler = :mail # (or :hoptoad )
  # config.safety_net.mail.host = 'localhost'
end
