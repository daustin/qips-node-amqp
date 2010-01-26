#############################################
####
#    David Austin - ITMAT @ UPENN     
#    Main Looping Daemon Code
#
#

require 'rubygems'
require 'right_aws'
require 'ruote'

# Generated remote participant for the ruote workflow engine
# (http://openwferu.rubyforge.org)

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  # config.trap( 'INT' ) do
  #   # do something clever
  # end
  # config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

# IMPORTANT CONFIGURATION NOTE
#
# Please review and update 'config/amqp.yml' accordingly if you wish to use
# AMQP as a transport mechanism for workitems sent between ruote and this
# daemon.

# Here lets set our startup stuff
rmi = StatusWriter.new(STATUS_FILE)
DaemonKit.logger.info "Using instance id: #{rmi.instance_id}"
DaemonKit.logger.info "Saving Status Messages to: #{STATUS_FILE}"
rmi.send_idle

# Configuration of the remote participant shell
begin
  DaemonKit::RuoteParticipants.configure do |config|
    # Use AMQP as a workitem transport mechanism
    config.use :amqp
    # Register your classes as pseudo-participants, with work being delegated
    # according to the 'command' parameter passed in the process definition
    config.register Sample
    config.register Worker

  end



  DaemonKit::RuoteParticipants.run do
    # Place any additional daemon-specific code in here...
    
  end

rescue  Exception => e
  
  rmi.send("error", nil, nil, "#{e.class}: #{e.message}")
  raise e
  
end


