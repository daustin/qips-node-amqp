# This is the same context as the environment.rb file, it is only
# loaded afterwards and only in the development environment

# NOTE: set listen queue(s) in ruote.yml

# dumps status to file so that cron can pick it up.
STATUS_FILE = '/Users/daustin/git_repos/qips-node-amqp/tmp/status.yml' #absolute path!

# meta url is where node looks to get it's instance ID
META_URL = 'http://localhost:3000/latest/meta-data/instance-id'

# this is the instance_id to use when not an AWS instance
ALT_INSTANCE_ID = 'i-abcd1234'

# working directory. this is where all the work's done on this node
WORK_DIR = '/Users/daustin/git_repos/qips-node-amqp/tmp/scratch'

#MD5 command to generate md5sums of files to verify they need to be uploaded
MD5_CMD = 'md5 -q'

