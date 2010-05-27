require 'activeresource'
require 'activesupport'

class Project < ActiveResource::Base
  self.site = ILIMS_SITE

  def items
    
    @items = Item.get(:index_all, :project_id => self.id )
    
  end
  
  def self.login_bypass(method, options = {})
    
    options[:method] = method
    
    self.get(:login_bypass, options )
    
  end
  
  
  
end