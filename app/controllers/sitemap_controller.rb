#http://blog.dynamic50.com/2012/08/10/automatic-sitemap-for-heroku-with-ruby-on-rails-3-2/
class SitemapController < ApplicationController
  def index
  	headers['Content-Type'] = 'application/xml'
  	base_url = "http://#{request.host_with_port}"
   @pages_to_visit1 =[]
  	if params[:static] == "true"
  	  date_object = Date.today.beginning_of_week + 1 <= Date.today ?     Date.today.beginning_of_week + 1 : "false"
      if date_object == false
        last_tuesday =  1.weeks.ago.beginning_of_week + 1
     else
        last_tuesday = date_object
     end 
  	    static_urls = [ {:url => base_url +'/car/search',      :updated_at => "", :priority => 0.8},
   					{:url => base_url +'/bike/search',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/cycle/search',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/camera/search',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/mobile/search',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/tablet/search',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/mobiles/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/bikes/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/tablets/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/cameras/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/cars/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/cycles/guides/Buyer%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},   	
   					{:url => base_url +'/cameras/guides/Beginner%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8},
   					{:url => base_url +'/cycles/guides/Beginner%20Guide',      :updated_at => I18n.l(last_tuesday.to_time, :format => :w3c), :priority => 0.8}				
   				 ]
      @pages_to_visit1+= static_urls
   end
   if params[:object_type] and params[:itemtype]
       item_type = Itemtype.find_by_itemtype(params[:itemtype])
       date_object = Date.today.beginning_of_week + 2 <= Date.today ?     Date.today.beginning_of_week + 2 : "false"
      if date_object == "false"
         last_wedday =  1.weeks.ago.beginning_of_week + 2
      else
         last_wedday = date_object
      end 
      if params[:object_type] == "item" 
        @pages_to_visit1+= item_type.items.collect{ |item| {:url =>  base_url + item.get_url() ,  :updated_at => I18n.l(last_wedday.to_time, :format => :w3c), :priority => 0.8 }}
      elsif params[:object_type] == "content"  
        @pages_to_visit1+= item_type.contents.collect{  |content| {:url =>  base_url + "/contents/" + content.id.to_s,  :updated_at => I18n.l(content.updated_at.nil?? Time.now : content.updated_at , :format => :w3c)} }
     elsif params[:object_type] == "original_content"
        @pages_to_visit1+= item_type.contents.where('type!=?','ArticleContent').collect{  |content| {:url =>  base_url + "/contents/" + content.id.to_s,  :updated_at => I18n.l(content.updated_at.nil?? Time.now : content.updated_at ,:format => :w3c)} }
        @pages_to_visit1+= ArticleContent.where('itemtype_id =? and url is  null ',item_type.id).collect{  |content| {:url =>  base_url + "/contents/" + content.id.to_s,  :updated_at => I18n.l(content.updated_at.nil?? Time.now : content.updated_at , :format => :w3c)} }
     elsif params[:object_type] == "compare_items" 
        items = item_type.items.paginate(:per_page => 600,:page => params[:page])
        @pages_to_visit1+= items.collect{ |item| Item.get_related_items(item, 3).size > 0 ? {:url =>  base_url + "/items/compare?ids=#{item.id},#{Item.get_related_items(item, 3).collect(&:id).join(",")}", :updated_at => I18n.l(last_wedday.to_time, :format => :w3c), :priority => 0.8 } : "bb" } 
        @pages_to_visit1.delete("bb")    
     end  
   else
     #@pages_to_visit1+= Item.all.collect{ |item| {:url =>  base_url + item.get_url() ,  :updated_at => I18n.l(item.updated_at.nil? ? Time.now : item.updated_at, :format => :w3c), :priority => 0.8 }}
     #@pages_to_visit1+= Content.all.collect{  |content| {:url =>  base_url + "/contents/" + content.id.to_s,  :updated_at => I18n.l(content.updated_at.nil?? Time.now : content.updated_at , :format => :w3c)} }
   end  
    respond_to do |format|
      format.xml {   @pages_to_visit=@pages_to_visit1}
    end
  
  end

end
