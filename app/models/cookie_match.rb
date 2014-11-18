class CookieMatch < ActiveRecord::Base


  scope :find_user, lambda {|plannto_user_id| where("plannto_user_id = '#{plannto_user_id}' and updated_at > '#{14.days.ago}'")}

  def self.check_cookie_user_exists?(plannto_user_id)
    matches = find_user(plannto_user_id)
    !matches.blank?
  end

  def self.enqueue_cookie_matching(param, plannto_user_id)
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => param["ref_url"], "source" => "google"}
    Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
  end

  def self.enqueue_pixel_matching(param, plannto_user_id)
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => "", "source" => "google_pixel"}
    Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
  end

  def self.process_cookie_matching(param)
    param["source"] ||= "google"
    cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(param["plannto_user_id"])
    cookie_match.update_attributes(:google_user_id => param["google_gid"], :match_source => param["source"])

    $redis_rtb.pipelined do
      $redis_rtb.set("cm:#{param['google_gid']}", param["plannto_user_id"])
      $redis_rtb.expire("cm:#{param['google_gid']}", 2.weeks)
    end

    if !param["ref_url"].blank?
      user_access_detail = UserAccessDetail.create(:plannto_user_id => param["plan_to_temp_user_id"], :ref_url => param["ref_url"], :source => param["source"])
    end
  end

  def self.buying_list_process_in_redis
    if $redis.get("buying_list_from_cookie_is_running").to_i == 0
      $redis.set("buying_list_from_cookie_is_running", 1)
      $redis.expire("buying_list_from_cookie_is_running", 30.minutes)
      length = $redis_rtb.llen("users:visits")
      base_item_ids = Item.get_base_items_from_config()
      source_categories = SourceCategory.get_source_category_with_paginations()
      t_length = length
      # start_point = 0

      begin
        user_vals = $redis_rtb.lrange("users:visits", 0, 1000)
        redis_rtb_hash = {}

        user_vals.each do |each_user_val|
          t_length-=1
          # p "Remaining Length each - #{t_length} - #{Time.now.strftime("%H:%M:%S")}"
          unless each_user_val.blank?
            user_id, url, type, item_ids, advertisement_id = each_user_val.split("<<")
            already_exist = Item.check_if_already_exist_in_user_visits(source_categories, user_id, url)
            ranking = 0

            if already_exist == false
              case type
                when "Reviews", "Spec", "Photo"
                  ranking = 10
                when "Comparisons"
                  ranking = 5
                when "Lists", "Others"
                  ranking = 2
              end

              item_ids = item_ids.to_s.split(",")
              if item_ids.count < 10

                u_key = "u:ac:#{user_id}"
                u_values = $redis.hgetall(u_key)

                # Remove expired items from user details
                u_values.each do |key,val|
                  if key.include?("_la") && val.to_date < 2.weeks.ago.to_date
                    item_id = key.gsub("_la", "")
                    u_values.delete("#{item_id}_c")
                    u_values.delete("#{item_id}_la")
                  end
                end

                # incrby count for items
                item_ids.each do |each_key|
                  if u_values["#{each_key}_c"].blank?
                    u_values["#{each_key}_c"] = ranking
                    u_values["#{each_key}_la"] = Date.today.to_s
                  else
                    old_ranking = u_values["#{each_key}_c"]
                    u_values["#{each_key}_c"] = old_ranking.to_i + ranking
                    u_values["#{each_key}_la"] = Date.today.to_s
                  end
                end

                proc_item_ids = u_values.map {|key,val| if key.include?("_c") && val.to_i > 30; key.gsub("_c",""); end}.compact

                old_buying_list = u_values["buyinglist"]
                buying_list = old_buying_list.to_s.split(",")

                if !buying_list.blank?
                  have_to_del = []

                  #remove items from buyinglist which detail is expired
                  buying_list.each do |each_item|
                    if !u_values.include?("#{each_item}_c") || u_values["#{each_item}_c"].to_i < 30
                      have_to_del << each_item
                    end
                  end

                  buying_list = buying_list - have_to_del
                  buying_list << proc_item_ids
                  buying_list = buying_list.flatten.uniq
                else
                  buying_list = proc_item_ids
                end

                buying_list = buying_list.delete_if {|each_item| base_item_ids.include?(each_item)}

                if !old_buying_list.blank? || !buying_list.blank?
                  u_values["buyinglist"] = buying_list.join(",")
                  items_count = u_values.select {|k,_| k.include?("_c")}.count
                  redis_rtb_hash.merge!("users:buyinglist:#{user_id}" => {"item_ids" => u_values["buyinglist"], "count" => items_count})
                end

                begin
                  if u_values.blank?
                    del_key = "users:buyinglist:#{user_id}"
                    $redis.del(u_key)
                    $redis_rtb.del(del_key)
                    redis_rtb_hash.delete(del_key)
                  else
                    $redis.pipelined do
                      $redis.hmset(u_key, u_values.flatten)
                      $redis.expire(u_key, 2.weeks)
                    end
                  end
                rescue Exception => e
                  p "Problems while hmset: Args:-"
                  p u_key
                  p u_values
                  p u_values.flatten
                  raise e
                end
              end
            end
          end
        end

        $redis_rtb.ltrim("users:visits", user_vals.count, -1) #TODO: temporary comment

        $redis_rtb.pipelined do
          redis_rtb_hash.each do |key, val|
            $redis_rtb.hmset(key, "item_ids", val["item_ids"], "count", val["count"])
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        length = length - 1001
        # start_point = start_point + 1001
        p "Remaining Length - #{length}"
      end while length > 0
      $redis.set("buying_list_from_cookie_is_running", 0)
    end
  end
end