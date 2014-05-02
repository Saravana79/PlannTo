class Click < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
  belongs_to :add_impression, :foreign_key => "impression_id"

  def self.create_new_record(obj_params)
    click = Click.new
    click.impression_id = obj_params[:impression_id]
    click.click_url = obj_params[:url]
    click.hosted_site_url = obj_params[:request_referer]
    click.timestamp = obj_params[:time]
    click.item_id = obj_params[:item_id]
    click.vendor_id = obj_params[:vendor_id]
    click.source_type = obj_params[:source_type]
    unless obj_params[:user].nil?
      click.user_id = obj_params[:user]
    end
    click.temp_user_id = obj_params[:temp_user_id]
    click.publisher_id = obj_params[:publisher]
    click.ipaddress = obj_params[:remote_ip]
    click.created_at = obj_params[:time]
    click.updated_at = obj_params[:time]
    click.save
  end

  def self.save_click_data(url,request_referer,time,item_id,user,remote_ip,impression_id,publisher,vendor_id,source_type,temp_user_id)
 #   click = Click.find_by_impression_id_and_source_type_and_item_id_and_hosted_site_url_and_temp_user_id_and_vendor_id_and_click_url(impression_id, source_type, itemid, request_referer, temp_user_id, vendor_id, url )
 #   unless click
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

          :joins => [:add_impression],
          :group => 'month(impression_time)',
          :conditions => { :add_impressions => {:advertisement_id => ad_id} , :timestamp => range }
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
          :joins => [:add_impression],
          :group => 'date(impression_time)',
          :conditions => { :add_impressions => {:advertisement_id => ad_id} , :timestamp => range }
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

  # def self.chart_data_widgets_for_click(publisher_id, start_date, end_date, types, vendor_id)
  #   if start_date.nil?
  #     start_date = 2.weeks.ago
  #   end
  #
  #   if end_date.nil?
  #     end_date = Date.today
  #   end
  #
  #   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)
  #
  #   conditions = { :add_impressions => {:advertisement_type => [types]}, :publisher_id => publisher_id , :timestamp => range, :vendor_id => vendor_id }
  #
  #   conditions.delete(:vendor_id) if vendor_id.blank?
  #
  #   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
  #
  #     kliks = count(
  #
  #         :joins => [:add_impression],
  #         :group => 'month(impression_time)',
  #         :conditions => conditions
  #     )
  #
  #     # CREATE JSON DATA FOR EACH MONTH
  #     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
  #       {
  #           impression_time: date.strftime("%b, %Y"),
  #           clicks: kliks[date.month] || 0
  #       }
  #     end
  #
  #
  #   else
  #
  #     kliks = count(
  #         :joins => [:add_impression],
  #         :group => 'date(impression_time)',
  #         :conditions => conditions
  #     )
  #
  #     #WORKS FINE DATA FOR EACH DAY
  #     (start_date.to_date..end_date.to_date).map do |date|
  #       {
  #           impression_time: date.strftime("%F"),
  #           clicks: kliks[date] || 0
  #       }
  #     end
  #   end
  # end

  #end
end
