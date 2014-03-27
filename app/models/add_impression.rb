class AddImpression < ActiveRecord::Base
 belongs_to :user
 belongs_to :item
 belongs_to :advertisement
 has_one :click, :foreign_key => "impression_id"

 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip,impression_id,itemsaccess=nil,params=nil, temp_user_id, ad_id)
  # ai = AddImpression.find_by_impression_id_and_advertisement_type_and_item_id_and_hosted_site_url_and_temp_user_id(impression_id, type, itemid, request_referer, temp_user_id )
  # unless ai
      ai = AddImpression.new
      ai.impression_id = impression_id
      ai.advertisement_type = type
      ai.item_id = itemid
      ai.hosted_site_url = request_referer
      ai.impression_time = time
      unless user.nil?
         ai.user_id = user.id
      end
      ai.temp_user_id = temp_user_id
      ai.ip_address = remote_ip
      ai.itemsaccess = itemsaccess
      ai.params = params
      publisher = Publisher.getpublisherfromdomain(request_referer)
      unless publisher.nil?
         ai.publisher_id = publisher.id
      end

      # save advertisement id
      ai.advertisement_id = ad_id
      ai.save 
  # end
   return ai.id
 end


 def self.chart_data(ad_id, start_date, end_date)
   if start_date.nil?
     start_date = 2.weeks.ago
   end

   if end_date.nil?
     end_date = Date.today
   end

   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s

     kliks = count(
         :group => 'month(impression_time)',
         :conditions => { :advertisement_id => ad_id, :impression_time => range }
     )

     # CREATE JSON DATA FOR EACH MONTH
     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
       {
           impression_time: date.strftime("%b, %Y"),
           clicks: kliks[date.month] || 0
       }
     end


   else

     kliks = count(
         :group => 'date(impression_time)',
         :conditions => { :advertisement_id => ad_id, :impression_time => range }
     )

     #WORKS FINE DATA FOR EACH DAY
     (start_date.to_date..end_date.to_date).map do |date|
       {
           impression_time: date.strftime("%F"),
           clicks: kliks[date] || 0
       }
     end
   end
 end

end

