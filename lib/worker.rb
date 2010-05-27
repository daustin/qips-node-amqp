#
# Sample pseudo participant
#
# called with the following workitem params:  :command => '<method>' :executable => 'ls -la' :args => ' arg1 arg2' :jid => '1234'
#

require 'rubygems'
require 'right_aws'
require 's3_helper'
require 'work_item_helper'
require 'json'
require 'item'

class Worker < DaemonKit::RuotePseudoParticipant

  def initialize 
    @s3 = RightAws::S3.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    @swr = StatusWriter.new(STATUS_FILE)
    @s3h = S3Helper.new(@s3)
  end

  on_exception :dammit

  on_complete do |workitem|
    workitem['success'] = true
    # @swr.send_idle # this doesn't work here and I don't know why!
  end

  ########
  #
  #  start_work sets up directory, downloads files, runs the command, and then re-uploads new files
  #

  def start_work
 
    #first lets  make sure the workitem is valid for this function
    unless WorkItemHelper.validate_workitem(workitem)
       raise ArgumentError, "Invalid workitem.  Check parameters."
    end

    # now we start processing.

    DaemonKit.logger.info "Starting work..."
    @swr.send("busy",  workitem.params['exec_timeout'], workitem.params['executable'])

    
    Dir.chdir(WORK_DIR) do 
      # clean directory
      system "rm -rf *"

      #
      #   here we're going to look at a few different ways to get files.
      #    - first we look for an array called input_files, and get them individually
      #    - then we'll look at input_bucket and then filter on input_filter to get other files
      #    - lastly, we'll look for previous output bucket, and get those files using filter
      #

      #First, lets get input files.  they should be in the form: 'mybucket:testdir/sub/file.txt'

      # infile list is an account of files that were downloaded
      infile_list = Hash.new
      infile_basenames = Array.new
      auxfile_basenames = Array.new
      params_basenames = Array.new

      DaemonKit.logger.info "Downloading input files..."
      infile_basenames = Item.download(workitem.params['input_files'].split(',')) unless workitem.params['input_files'].nil? || workitem.params['input_files'].empty?
      # infile_basenames = @s3h.download_all(workitem.params['input_files'].split(',')) unless workitem.params['input_files'].nil? || workitem.params['input_files'].empty?
      
      DaemonKit.logger.info "Downloading params file..."
      params_basenames = @s3h.download_all(workitem.params['params_file'].split(',')) unless (workitem.params['params_file'].nil? || workitem.params['params_file'].empty?)
      
      DaemonKit.logger.info "Downloading auxiliary files..."
      auxfile_basenames = Item.download(workitem.params['aux_files'].split(',')) unless workitem.params['aux_files'].nil? || workitem.params['aux_files'].empty?
      # auxfile_basenames = @s3h.download_all(workitem.params['aux_files'].split(',')) unless workitem.params['aux_files'].nil? || workitem.params['aux_files'].empty?
      
      infile_list = @s3h.get_md5_sums(infile_basenames + auxfile_basenames + params_basenames) # deprecated for now
      
      DaemonKit.logger.info "Downloaded #{infile_list.keys.size} files."

      #now we run the command based on the params, and store it's output in a file
      args = workitem.params['args'] ||= ''
      
      infiles_arg = ''
      
      infiles_arg = "--input_files='#{infile_basenames.join(',')}'" if workitem.params['pass_filenames'].eql?("true")
      
      DaemonKit.logger.info "Running Command #{workitem.params['executable']} #{args} #{infiles_arg}..."
  
      #now we examine out and see if we can parse it 
      out = `#{workitem.params['executable']} #{args} #{infiles_arg}`
      
      DaemonKit.logger.info "Found output:"
      puts out
      
      output_hash = Hash.new
      
      begin
        
        output_hash = JSON.parse(out)
        raise "not a hash" unless output_hash.class.to_s.eql?("Hash")
        
      rescue
        
        DaemonKit.logger.info "Could not parse executable's output as JSON.  Using raw output..."
        output_hash = Hash.new
        output_hash["result"] = out
        
      end
      
      # set executable result and crash on error
      workitem["result"] = output_hash["result"]
      
      raise "#{output_hash['error']}" if output_hash.has_key?("error")      
      
      #now lets upload and set output files based on hash
      
      #get the apropriate output bucket
      output_folder = workitem['previous_output_folder'] ||= workitem.params['output_folder']
      
      workitem['previous_output_folder'] = output_folder # set previous output folder for future reference
      
      DaemonKit.logger.info "Uploading Output Files..."
      
      #first dup upload / output files if necessary
      output_hash["upload_files"] = output_hash["output_files"] if output_hash.has_key?("output_files") && ! output_hash.has_key?("upload_files")
      output_hash["output_files"] = output_hash["upload_files"] if output_hash.has_key?("upload_files") && ! output_hash.has_key?("output_files")
      
      #now lets set output & upload
      
      if output_hash.has_key?("output_files") && output_hash.has_key?("upload_files")
        #use hash values
        @s3h.upload_all(output_hash["upload_files"], output_folder)
        
        #need to pass the output folder along with output_files
        s3_outs = output_hash["output_files"].collect {|o| "#{output_folder}#{o}"}
        workitem["output_files"] = Array.new 
        workitem["output_files"] = s3_outs
      
      end
            
      @swr.send_idle

    end

    
     
  end

  def err
    raise ArgumentError, "Invalid workitem.  Check parameters."
    @swr.send_error
  end

  def dammit( exception )
    workitem["error"] = exception.message
    @swr.send_error
  end

end
