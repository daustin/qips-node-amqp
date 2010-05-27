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
  
  def self.upload(filenames, project_id)
    
    
  end
  
end