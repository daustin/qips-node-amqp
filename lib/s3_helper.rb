#################################################
###
##     David Austin - ITMAT @ UPENN
#      S3 Helper  downloads and uploads files and validates s3 paths 
#
#
####  

class S3Helper


  def initialize (s3)
    # set s3 instance
    @s3 = s3

  end

  #################
  #
  #  expects an array of s3 paths. returns an array of basenames
  #

  def download_all (file_array)
    basenames = Array.new
    file_array.each do |fn|
      download(fn)
      basenames << fn unless fn.nil?      
    end
    
  end

  ######################
  #
  #  downloads a single s3 file from path. returns basename
  #

  def download (file)
    return nil unless validate_s3(file)
    fname_array = file.split(':')
    bucket_name = fname_array[0]
    key_name = fname_array[1]
    # downloads a single file onto a local directory, returns basename of file
    bucket = RightAws::S3::Bucket.create(@s3, bucket_name, false)
    key = RightAws::S3::Key.create(bucket, key_name)
    fname = File.basename(key_name)
    File.open(fname, "w+") { |f| f.write(key.data) }
    DaemonKit.logger.info "Downloaded #{bucket}:#{key.to_s} --> #{fname} "
    return fname
    
  end
  
  

  ###############################################
  #
  #   uploads a single file to an s3 folder. 
  #

  def upload (fname, folder)
    
    return nil unless validate_s3(folder)
    fname_array = folder.split(':')
    bucket_name = fname_array[0]
    key_name = fname_array[1].chomp('/') + '/'
    key = RightAws::S3::Key.create( bucket = RightAws::S3::Bucket.create(@s3, bucket_name, false), "#{key_name}#{fname}")
    key.data = File.new(fname).read
    key.put
    DaemonKit.logger.info "Uploaded #{f} --> #{bucket}:#{key.to_s}"
    
  end


  #######################################################################
  #
  #  uploads all files in array, unless they appear in the exclude list or have same md5 in list
  #
  
  def upload_all (basenames, folder, exclude_list=nil, carry_exec_out=false)
    return nil unless validate_s3(folder)
    uploaded_list = Array.new
    basenames.each do |f|
      md5 = `#{MD5_CMD} #{f}`
      unless (! exclude_list.nil?) && exclude_list.keys.include?(f) && exclude_list[f].eql?(md5)
        upload(f, folder)
        uploaded_list << "#{bucket}:#{key.to_s}" if f.index('exec_output.txt').nil? || carry_exec_out
        DaemonKit.logger.info "Uploaded #{f} --> #{bucket}:#{key.to_s}"
      end
    end
    
    return uploaded_list
    
  end
  
  ###########################################
  #
  #  uploads all files in cwd, unless they appear in the exclude list
  #
  
  def upload_cwd (folder, exclude_list=nil, carry_exec_out=false)
    # upload all files in cwd to folder, except the ones in exclude list
    return nil unless validate_s3(folder)
    basenames = Dir.glob("*.*")
    return upload_all(basenames, folder, exclude_list, carry_exec_out)
    
  end

  #############################################
  #
  # returns a hash of basenames and their current md5sums for comparison.
  # feed this list to upload methods
  #
  
  def get_md5_sums(basenames)
    
    h = Hash.new
    basenames.each do |f|
      
      h["#{f}"] = `#{MD5_CMD} #{f}`
      
    end
    
    return h
    
    
  end




  ############################################
  #
  #  make sure s3 path is valid
  #

  def validate_s3 (s)
    if s.index(':').nil?
      # invalid bucket!
      return false
    else
      return true
    end
    
  end
  


end
