class Click < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
  def self.save_click_data(url,request_referer,time,item_id,user,remote_ip,impression_id,publisher)
    click = Click.new
    click.impression_id = impression_id
    click.click_url = url
    click.hosted_site_url = request_referer
    click.timestamp = time
    click.item_id = item_id
    click.user_id = user
    click.publisher_id = publisher.id rescue nil
    click.ipaddress = remote_ip
    click.save
  end
end
