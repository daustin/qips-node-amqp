#################################################
###
##     David Austin - ITMAT @ UPENN
#      S3 Helper  downloads and uploads files 
#
#
####  

class S3Helper


  def initialize (s3)
    # set s3 instance
    @s3 = s3

  end

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

  def download_folder (folder, filter=nil)
    flist = Array.new
    return flist unless validate_s3(folder)
    #get all keys from folder, filtering out
    fname_array = folder.split(':')
    bucket_name = fname_array[0]
    key_name = fname_array[1].chomp('/') + '/'
    bucket = RightAws::S3::Bucket.create(@s3, bucket_name, false)
    keys = bucket.keys(:prefix => key_name)
    filter = '.+' if filter.nil?
    # download all files from folder, applying filter to keys, returns array of basenames
    keys.each do |k|
      # now we enumerate through each key and download it, if matches
      fname = File.basename(k.to_s)
      flist << download("#{bucket_name}:#{k.to_s}") if fname.match(filter)
                           
    end

    return flist

  end

  def upload (folder, exclude_list=nil)
    # upload all files in cwd to folder, except the ones in exclude list
    return nil unless validate_s3(folder)
    uploaded_list = Array.new
    fname_array = folder.split(':')
    bucket_name = fname_array[0]
    key_name = fname_array[1].chomp('/') + '/'
    Dir.glob("*.*").each do |f|
      md5 = `#{MD5_CMD} #{f}`
      unless (! exclude_list.nil?) && exclude_list.keys.include?(f) && exclude_list[f].eql?(md5)
        key = RightAws::S3::Key.create( bucket = RightAws::S3::Bucket.create(@s3, bucket_name, false),
                                        "#{key_name}#{f}")
        key.data = File.new(f).read
        key.put
        uploaded_list << "#{bucket}:#{key.to_s}" if f.index('exec_output.txt').nil?
        DaemonKit.logger.info "Uploaded #{f} --> #{bucket}:#{key.to_s}"
      end
    end
    
    return uploaded_list
    
  end


  def validate_s3 (s)
    if s.index(':').nil?
      # invalid bucket!
      return false
    else
      return true
    end
    
  end
  


end
