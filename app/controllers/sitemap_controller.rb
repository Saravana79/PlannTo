#http://blog.dynamic50.com/2012/08/10/automatic-sitemap-for-heroku-with-ruby-on-rails-3-2/
class SitemapController < ApplicationController
  def index
  	headers['Content-Type'] = 'application/xml'
  	base_url = "http://#{request.host_with_port}"
   	static_urls = [ {:url => base_url +'/car/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/bike/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/cycle/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/camera/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/mobile/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/tablet/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/mobiles/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/bikes/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/tablets/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/cameras/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/cars/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/cycles/guides/Buyer%20Guide',      :updated_at => "", :priority => 0.8},   	
   					{:url => base_url +'/cameras/guides/Beginner%20Guide',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/cycles/guides/Beginner%20Guide',      :updated_at => "", :priority => 0.8}				
   				 ]
   @pages_to_visit1  = static_urls
   @pages_to_visit1+= Item.all.collect{ |item| {:url =>  base_url + item.get_url() ,  :updated_at => I18n.l(item.updated_at.nil? ? Time.now : item.updated_at, :format => :w3c), :priority => 0.8 }}
   @pages_to_visit1+= Content.all.collect{  |content| {:url =>  base_url + "/contents/" + content.id.to_s,  :updated_at => I18n.l(content.updated_at.nil?? Time.now : content.updated_at , :format => :w3c)} }
    
    respond_to do |format|
      format.xml {   @pages_to_visit=@pages_to_visit1}
    end
  
  end

end
