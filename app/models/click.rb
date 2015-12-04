class Click < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
  belongs_to :add_impression, :foreign_key => "impression_id"

  attr_accessor :t, :r, :ic, :a, :video_impression_id

  belongs_to :advertisement

  def self.create_new_record(obj_params)
    unless obj_params.is_a?(Hash)
      obj_params = JSON.parse(obj_params)
    end
    # obj_params = obj_params.symbolize_keys

    last_click_details = "#{obj_params["url"]}-#{obj_params["request_referer"]}-#{obj_params["remote_ip"]}"

    last_20_clicks = $redis_rtb.lrange("ads_last_20_clicks", 0, 19)
    click = nil
    unless last_20_clicks.include?(last_click_details)
      click = Click.new
      click.impression_id = obj_params["impression_id"]
      click.click_url = obj_params["url"]
      click.hosted_site_url = obj_params["request_referer"]
      click.timestamp = obj_params["time"]
      click.item_id = obj_params["item_id"]
      click.vendor_id = obj_params["vendor_id"]
      click.source_type = obj_params["source_type"]
      unless obj_params["user"].nil?
        click.user_id = obj_params["user"]
      end
      click.temp_user_id = obj_params["temp_user_id"]
      click.publisher_id = obj_params["publisher"]
      click.ipaddress = obj_params["remote_ip"]
      click.advertisement_id = obj_params["advertisement_id"]
      click.sid = obj_params["sid"]
      click.created_at = obj_params["time"]
      click.updated_at = obj_params["time"]

      # extra params
      click.t = obj_params["t"]
      click.r = obj_params["r"]
      click.ic = obj_params["ic"]
      click.a = obj_params["a"]
      click.video_impression_id = obj_params["video_impression_id"].to_s

      Click.redis_push(last_click_details)
      push_to_redis(click.temp_user_id, click.advertisement_id) if (!click.temp_user_id.blank? && !click.advertisement_id.blank?)
    end

    return click
  end

  def self.push_to_redis(user_id, advertisement_id)
    $redis_rtb.pipelined do
      $redis_rtb.incrby("pu:#{user_id}:#{advertisement_id}:clicks:count",1)
      $redis_rtb.expire("pu:#{user_id}:#{advertisement_id}:clicks:count",2.weeks)

      $redis_rtb.incrby("pu:#{user_id}:#{advertisement_id}:clicks:#{Date.today.day}",1)
      $redis_rtb.expire("pu:#{user_id}:#{advertisement_id}:clicks:#{Date.today.day}",1.day)
    end
  end

  def self.redis_push(last_click_details)
    $redis_rtb.lpush("ads_last_20_clicks", last_click_details)
    $redis_rtb.ltrim("ads_last_20_clicks", 0, 19)
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
          :conditions => { :add_impressions1 => {:advertisement_id => ad_id} , :timestamp => range }
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

  def self.get_item_details_when_ad_not_as_widget(impression_type, item_details, vendor_ids)
    @item_details = item_details
    if impression_type != "advertisement_widget" && @item_details.blank?
      unless $redis.get("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}").blank?
        @item_details = Itemdetail.get_item_details($redis.get("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}"), vendor_ids)
      end
      if @item_details.blank?
        clicks = Click.where("vendor_id in (?)", vendor_ids).order("created_at desc").limit(10)
        clicks.each do |click|
          @item_details = Itemdetail.get_item_details(click.item_id, vendor_ids)
          unless @item_details.blank?
            $redis.set("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}", click.item_id)
            $redis.expire("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}", 86400)
            break
          end
        end
      end
    end
    @item_details
  end
  
  def self.update_url_tag_and_subtag(url, publisher_vendor, impression_id)
    if url.include?("tag")
      # url = URI.unescape(url)
      # if url.include?("%")
      #   url = URI.unescape(url)
      # end
      tag_val = FeedUrl.get_value_from_pattern(url, "tag=<tag_val>&", "<tag_val>")
      
      if tag_val.blank?
        url = URI.unescape(url)
        tag_val = FeedUrl.get_value_from_pattern(url, "tag=<tag_val>&", "<tag_val>")
        tag_val = FeedUrl.get_value_from_pattern(url, "tag=<tag_val>", "<tag_val>") if tag_val.blank?
      end

      url = url.gsub("tag=#{tag_val}", "tag=#{publisher_vendor.trackid}") if tag_val.blank?
      url = url.gsub(tag_val, "#{publisher_vendor.trackid}") if tag_val.include?("INSERT_TAG_HERE")
      url = url.gsub(tag_val, "#{publisher_vendor.trackid}") if tag_val.include?("pla04-21")

      if !url.include?("ascsubtag")
        url = url + "&ascsubtag=#{impression_id}"
      else
        ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>&", "<tag_val>")

        if ascsubtag.blank?
          url = URI.unescape(url)
          ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>&", "<tag_val>")
          ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>", "<tag_val>") if ascsubtag.blank?

          if ascsubtag.blank?
            url = url.gsub("ascsubtag=", "")
            url = url + "&ascsubtag=#{impression_id}"
          end
        end
      end
    elsif url.include?("asscsubtag")
      ascsubtag_val = ""
      ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>", "<tag_val>")

      if ascsubtag.blank?
        url = URI.unescape(url)
        ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>&", "<tag_val>")
        ascsubtag = FeedUrl.get_value_from_pattern(url, "ascsubtag=<tag_val>", "<tag_val>") if ascsubtag.blank?

        if ascsubtag.blank?
          ascsubtag_val = "ascsubtag=#{impression_id}"
          url = url.gsub("ascsubtag=", "")
        end
      end

      if url.include?("?")
        url = url + "&tag=#{publisher_vendor.trackid}#{ascsubtag_val.blank? ? "" : "&#{ascsubtag_val}"}"
      else
        url = url + "?tag=#{publisher_vendor.trackid}#{ascsubtag_val.blank? ? "" : "&#{ascsubtag_val}"}"
      end
    else
      if url.include?("?")
        url = url + "&tag=#{publisher_vendor.trackid}&ascsubtag=#{impression_id}"
      else
        url = url + "?tag=#{publisher_vendor.trackid}&ascsubtag=#{impression_id}"
      end
    end

    url
  end
end
