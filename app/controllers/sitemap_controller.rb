class SitemapController < ApplicationController
  def index
   static_urls = [ {:url => '/car/search',      :updated_at => ""}]
   @pages_to_visit = Item.all.collect{  |a| {:url => item_path(a) ,  :updated_at => I18n.l(a.updated_at, :format => :w3c)} }
 
    respond_to do |format|
      format.html
    end
  
  end

end
