####################################
####
#    David Austin - ITMAT @ UPENN
#    Interfaces to a remote resource manager via HTTP
#    

require 'rubygems'
require 'json'
require 'net/http'


class ResourceManagerInterface 
  
  attr_reader :instance_id

  #calls get
  def initialize(surl)

    @status_url = surl
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


  def send(state, timeout = nil)
    
    timestamp = Time.new.strftime("%Y%m%d%H%M%S")
    
    url = "#{@status_url.chomp('/')}/#{@instance_id}?state=#{state}&timestamp=#{timestamp}"
    
    url += "&timeout=#{timeout}" unless timeout.nil?
    
    DaemonKit.logger.info "Sending state #{state}..."
    DaemonKit.logger.info "#{url}"
    
    #send state to rmgr via http request
    begin
      resp = Net::HTTP.get_response(URI.parse(url))

    rescue => e
      DaemonKit.logger.error "Caught Exception while trying to set state: #{e.message}"
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
