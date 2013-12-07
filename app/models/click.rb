class Click < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
  def self.save_click_data(url,request_referer,time,item_id,user,remote_ip,impression_id,publisher,vendor_id,source_type,temp_user_id)
    click = Click.find_by_impression_id_and_source_type_and_item_id_and_hosted_site_url_and_temp_user_id_and_vendor_id_and_click_url(impression_id, source_type, itemid, request_referer, temp_user_id, vendor_id, url )
    unless click
      click = Click.new
      click.impression_id = impression_id
      click.click_url = url
      click.hosted_site_url = request_referer
      click.timestamp = time
      click.item_id = item_id
      click.vendor_id = vendor_id
      click.source_type = source_type
      unless user.nil?
        click.user_id = user.id
      end
      click.temp_user_id = temp_user_id
      click.publisher_id = publisher.id rescue nil
      click.ipaddress = remote_ip
      click.save
    end
  end
end
