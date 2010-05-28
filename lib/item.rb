require 'activeresource'
require 'activesupport'
require 'project'

class Item < ActiveResource::Base
  self.site = ILIMS_SITE
  
  def self.download(project_attachment_ids, work_dir = WORK_DIR) 
    
    ids = Array.new
    fnames = Array.new
    
    if project_attachment_ids.class.to_s.eql?("Array") 
      ids = project_attachment_ids
    else
      ids << project_attachments_ids
    end
    
    Dir.chdir(work_dir) do 
      ids.each do |i|
     
          #first find project attachment to get the filename and item id
          pa = Project.login_bypass(:find_project_attachment_by_id, :id => i) 
          unless pa.nil? || pa['item'].nil?       
            `#{WGET_CMD} -O #{pa['item']['attachment_file_name']} '#{ILIMS_SITE}/items/#{pa['item']['id']}/download_bypass'`
            fnames << "#{pa['item']['attachment_file_name']}"
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
      h = Hash.from_xml(res.content)['hash']
      results << h 
      
    end
    
    return results
      
  end
  
end