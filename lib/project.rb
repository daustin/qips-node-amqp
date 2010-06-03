require 'activeresource'
require 'activesupport'

class Project < ActiveResource::Base
  self.site = ILIMS_SITE

  def items
    
    # GET /projects/1/items.xml
    res = connection.get("#{self.class.prefix}#{self.class.collection_name}/#{self.id}/items")
    
  end

  
end