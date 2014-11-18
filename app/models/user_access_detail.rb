class UserAccessDetail < ActiveRecord::Base

  after_save :update_buying_list_in_redis

  def update_buying_list_in_redis
    article_content = ArticleContent.where(:url => ref_url).last

    unless article_content.blank?
      user_id = plannto_user_id
      type = article_content.sub_type
      item_ids = article_content.item_ids.join(",") rescue ""
      UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids)
    end
  end

  def self.update_buying_list(user_id, url, type, item_ids)
    # user_id, url, type, item_ids, advertisement_id = each_user_val.split("<<")
    base_item_ids = Item.get_base_items_from_config()
    source_categories = SourceCategory.get_source_category_with_paginations()
    redis_rtb_hash = {}

    already_exist = Item.check_if_already_exist_in_user_visits(source_categories, user_id, url, url_prefix="users:last_visits:plannto")
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

        u_key = "u:ac:plannto:#{user_id}"
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

        # if !old_buying_list.blank? || !buying_list.blank?
          u_values["buyinglist"] = buying_list.join(",")
          items_hash = u_values.select {|k,_| k.include?("_c")}
          items_count = items_hash.count
          all_item_ids = Hash[items_hash.sort_by {|k,v| v}.reverse].map {|k,v| k.gsub("_c","")}.compact
          all_item_ids = all_item_ids.join(",")
          redis_rtb_hash.merge!("users:buyinglist:plannto:#{user_id}" => {"item_ids" => u_values["buyinglist"], "count" => items_count, "all_item_ids" => all_item_ids})
        # end

        begin
          if u_values.blank?
            del_key = "users:buyinglist:plannto:#{user_id}"
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

    $redis_rtb.pipelined do
      redis_rtb_hash.each do |key, val|
        $redis_rtb.hmset(key, "item_ids", val["item_ids"], "count", val["count"], "all_item_ids", val["all_item_ids"])
        $redis_rtb.expire(key, 2.weeks)
      end
    end
  end
end
