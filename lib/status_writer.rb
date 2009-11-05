####################################
####
#    David Austin - ITMAT @ UPENN
#    Sets Stat in a YAML file
#    

require 'rubygems'
require 'json'
require 'net/http'
require 'yaml'

class StatusWriter 
  
  attr_reader :instance_id

  #calls get
  def initialize(s)

    @status_filename = "#{DAEMON_ROOT}/#{s}"
    @instance_id = get_instance_id
  end

  def get_instance_id
    #fetches instance id from AWS meta services
    begin
      resp = Net::HTTP.get_response(URI.parse(META_URL))
      data = resp.body

    rescue
      data = ALT_INSTANCE_ID
    end
    
    return data
    
  end


  def send(state, timeout = nil, ps = nil)
    
    timestamp = Time.new.strftime("%Y%m%d%H%M%S")
    
    to_save = Hash.new
    
    DaemonKit.logger.info "Sending state #{state}..."
    
    to_save['instance_id'] = @instance_id
    to_save['state'] = state
    to_save['timestamp'] = timestamp
    to_save['ruby_pid'] = "#{Process.pid}"
    to_save['timeout'] = timeout unless timeout.nil?
    to_save['executable'] = ps unless ps.nil?

    File.open( "#{@status_filename}", 'w' ) do |out|
        YAML.dump( to_save, out)
    end
   
  end

  
  def method_missing(method)
    if method.to_s.match(/send_(.+)/)
      send($1)
    else
      raise NoMethodError
    end
  end

end
