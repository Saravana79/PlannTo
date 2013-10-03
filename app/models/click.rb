class Click < ActiveRecord::Base

  def self.save_click_data(url,request_referer,time,item_id,user,remote_ip)
    click = Click.new
    click.impression_id = nil
    click.click_url = url
    click.hosted_site_url = request_referer
    click.timestamp = time
    click.item_id = item_id
    click.user_id = user
    click.ipaddress = remote_ip
    click.save
  end
end
