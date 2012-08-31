class SitemapController < ApplicationController
  def index
   static_urls = [ {:url => 'http://wwww.plannto.com/car/search', :updated_at => ""}]
   @pages_to_visit  = static_urls
   @pages_to_visit+= Item.all.collect{  |a| {:url => "http://www.plannto.com" + item_path(a) ,  :updated_at => I18n.l(a.updated_at, :format => :w3c)} }
 
    respond_to do |format|
      format.xml{ render :xml =>  @pages_to_visit}
    end
  
  end

end
