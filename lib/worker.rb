#
# Sample pseudo participant
#
# called with the following workitem params:  :command => '/worker/<method>' :executable => 'ls -la' :args => ' arg1 arg2' :jid => '1234'
#

require 'rubygems'
require 'right_aws'
require 's3_helper'
require 'work_item_helper'

class Worker < DaemonKit::RuotePseudoParticipant

  def initialize 
    @s3 = RightAws::S3.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    @rmi = StatusWriter.new(STATUS_FILE)
    @s3h = S3Helper.new(@s3)
  end

  on_exception :dammit

  on_complete do |workitem|
    workitem['success'] = true
    # @rmi.send_idle # this doesn't work here and I don't know why!
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
    @rmi.send("busy",  workitem.params['sqs_timeout'], workitem.params['executable'])

    
    Dir.chdir(WORK_DIR) do 
      # clean directory
      system "rm -rf *"

      #
      # here we're going to look at a few different ways to get files.
      #    - first we look for an array called input_files, and get them individually
      #    - then we'll look at input_bucket and then filter on input_filter to get other files
      #    - lastly, we'll look for previous output bucket, and get those files using filter
      #

      #First, lets get input files.  they should be in the form: 'mybucket:testdir/sub/file.txt'

      # infile list is an account of files that were downloaded
      infile_list = Hash.new
      input_folder = ''

      unless workitem.params['input_files'].nil?
        # now download each file
        DaemonKit.logger.info "Found Input file list. Downloading..."
        a = workitem.params['input_files'].split
        #get folder info
        if a[0].rindex('/').nil?
          input_folder = a[0]
        else
          input_folder = a[0][0..(a[0].rindex('/')-1)]
        end
        a.each do |f|
          f_name = @s3h.download(f)
          infile_list["#{f_name}"] = `#{MD5_CMD} #{f_name}`
        end
      end

      #now lets look at the case where an entire folder is specified.  download entire folder, with filter, do the same for previous output
      unless workitem.params['input_folder'].nil?
        DaemonKit.logger.info "Found input folder #{workitem.params['input_folder']}. Downloading..."
        input_folder = workitem.params['input_folder']
        infile_array = @s3h.download_folder(workitem.params['input_folder'], workitem.params['input_filter'])
        infile_array.each do |f|
          infile_list["#{f}"] = `#{MD5_CMD} #{f}`
          
        end
        
        
      end

      # finally lets get previous output folder if all else fails.

      if  workitem.params['input_files'].nil? && workitem.params['input_folder'].nil? && workitem['previous_output_folder'].nil?
        DaemontKit.logger.info "Using previous output folder for inputs. Downloading..."
        input_folder =  workitem['previous_output_folder']
        infile_array = @s3h.download_folder(workitem['previous_output_folder'], workitem.params['input_filter'])
        infile_array.each do |f|
          infile_list["#{f}"] = `#{MD5_CMD} #{f}`
          
        end
        
      end

      DaemonKit.logger.info "Downloaded #{infile_list.keys.size} files."

      #now we run the command based on the params, and store it's output in a file
      args = workitem.params['args'] ||= ''
      
      DaemonKit.logger.info "Running Command #{workitem.params['executable']} #{args}..."
 
      out = `#{workitem.params['executable']} #{args}`
      
      puts out
      
      File.open("#{workitem.fei['wfid']}_#{workitem.fei['expid']}_exec_output.txt", "w") { |f| f.write(out) }

      #now lets put the files back into the output bucket
      output_folder = workitem['previous_output_folder'] ||= workitem.params['output_folder'] ||= input_folder
      
      workitem['previous_output_folder'] = output_folder # set previous output folder for future reference
      
      DaemonKit.logger.info "Uploading Output Files..."

      workitem["output_files_#{workitem.fei['expid']}"] = Array.new 
      workitem["output_files_#{workitem.fei['expid']}"] << @s3h.upload(output_folder, infile_list)
      
      @rmi.send_idle

    end

    
     
  end

  def err
    raise ArgumentError, "Invalid workitem.  Check parameters."
    @rmi.send_error
  end

  def dammit( exception )
    workitem["error"] = exception.message
    @rmi.send_error
  end

end
