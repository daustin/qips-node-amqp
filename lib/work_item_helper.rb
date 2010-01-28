require 'ruote'

class WorkItemHelper

  def self.validate_workitem (wi)
    #work items need to have certain information in their parameters in order for the node to work
    #this method will check and see

    valid = true
    
    #first make sure this has a PID and command
    if wi.params['executable'].nil?
      valid = false
    end

    #then check and make sure it has an input bucket, or a prev_output bucket
    if wi.params['input_folder'].nil?  &&  wi.params['input_files'].nil? && ! wi.has_attribute?('prev_output_bucket')
      valid = false
    end

    return valid
  end



  def self.decode_message (message)
    message = Base64.decode64(message)
    hash = Rufus::Json.decode( message )
    Ruote::Workitem.new( hash )
    
  end

  def self.encode_workitem (wi)
    msg = wi.to_h.to_json
    msg = Base64.encode64(msg)
    msg
    
    
  end
  
end

