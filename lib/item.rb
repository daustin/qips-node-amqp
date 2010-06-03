require 'activeresource'
require 'activesupport'
require 'project'

class Item < ActiveResource::Base
  self.site = ILIMS_SITE
  
  def self.download(item_ids, work_dir = WORK_DIR) 
    
    ids = Array.new
    fnames = Array.new
    
    if item_ids.class.to_s.eql?("Array") 
      ids = item_ids
    else
      ids << item_ids
    end
    
    Dir.chdir(work_dir) do 
      ids.each do |i|
     
          #first find item, then download it! 
          item = Item.find(i) 
          puts item.inspect
          unless item.nil?       
            `#{WGET_CMD} -O #{item.attachment_file_name} '#{ILIMS_SITE}/items/#{item.id}/download.xml'`
            fnames << "#{item.attachment_file_name}"
          end
      end
    end
    
    return fnames
    
  end 
  
  # uploads a list of files to the lims. returns an array of hashes containing item_is, project_id, and project_attachment_id
  
  def self.upload(filenames, user_id, project_id = '', work_dir = WORK_DIR)
    
    # array to return
    results = Array.new
    
    # HTTP client (active resource can't handle multipart)
    clnt = HTTPClient.new
    domain = nil
    user = ILIMS_USERNAME
    password = ILIMS_PASS
    clnt.set_auth(domain, user, password)
    
        
    #first we make the upload array
    
    upload_array = Array.new
    
    if filenames.class.to_s.eql?("Array") 
      upload_array = filenames
    else
      upload_array << filenames
    end
    
    # upload each file
    
    upload_array.each do |fn|
      
      # now we upload!
      
      puts "Uploading #{work_dir}/#{fn} to ilims..."
      body = { :attachment => File.open( "#{work_dir}/#{fn}"), :user_id => user_id, :project_id => project_id }   
      res = clnt.post("#{ILIMS_SITE}/items/upload_bypass.xml", body)
      h = Hash.from_xml(res.content)['item']
      results << h
      
    end
    
    return results
      
  end
  
end