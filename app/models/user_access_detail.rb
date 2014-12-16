class UserAccessDetail < ActiveRecord::Base

  # after_save :update_buying_list_in_redis

  def update_buying_list_in_redis(source_categories=nil)
    article_content = ArticleContent.where(:url => ref_url).last

    unless article_content.blank?
      user_id = plannto_user_id
      type = article_content.sub_type
      item_ids = article_content.item_ids.join(",") rescue ""
      UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories, source)
    end
  end

  def self.update_buying_list(user_id, url, type, item_ids,source_categories=nil, source="google")
    # user_id, url, type, item_ids, advertisement_id = each_user_val.split("<<")
    base_item_ids = Item.get_base_items_from_config()
    # source_categories = SourceCategory.get_source_category_with_paginations()
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
        when "Vendor"
          ranking = 15
      end

      item_ids = item_ids.to_s.split(",")
      if item_ids.count < 10

        u_key = "u:ac:plannto:#{user_id}"
        u_values = $redis.hgetall(u_key)

        add_fad = u_values.blank? ? true : false

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

        # Above 30 Ranking
        buying_list = get_buying_list_above(30, u_values, "buyinglist", base_item_ids)

        # Above 30 Ranking
        buying_list_20 = get_buying_list_above(20, u_values, "buyinglist_20", base_item_ids)


        #buying soon check
        top_sites = ["savemymoney.com", " couponrani.com", "mysmartprice.com", "findyogi.com", "findyogi.in", "smartprix.com", "pricebaba.com"]
        host = Item.get_host_without_www(url)
        bs = top_sites.include?(host)

        # if !old_buying_list.blank? || !buying_list.blank?
          u_values["buyinglist"] = buying_list.join(",")
          u_values["buyinglist_20"] = buying_list_20.join(",")
          existing_source = u_values["source"].to_s
          existing_source = existing_source.split(",").compact
          existing_source << source
          new_source = existing_source.uniq
          u_values["source"] = new_source.join(",")
          items_hash = u_values.select {|k,_| k.include?("_c")}
          items_count = items_hash.count
          all_item_ids = Hash[items_hash.sort_by {|_,v| v.to_i}.reverse].map {|k,_| k.gsub("_c","")}.compact
          all_item_ids = all_item_ids.join(",")
          temp_store = {"item_ids" => u_values["buyinglist"], "item_ids_20" => u_values["buyinglist_20"], "count" => items_count, "all_item_ids" => all_item_ids, "lad" => Date.today.to_s, "source" => new_source.join(",")}
          temp_store.merge!("bs" => bs, "bsd" => Date.today.to_s) if bs
          temp_store = temp_store.merge("fad" => Date.today.to_s) if add_fad
          redis_rtb_hash.merge!("users:buyinglist:plannto:#{user_id}" => temp_store)
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
              $redis.expire(u_key, 3.weeks)
            end
          end
        rescue Exception => e
          p "Problems while hmset: Args:-"
          p u_key
          p u_values
          p u_values.flatten
          p e
        end
      end
    end

    # $redis_rtb.pipelined do
    #   redis_rtb_hash.each do |key, val|
    #     $redis_rtb.hmset(key, val.flatten)
    #     $redis_rtb.hincrby(key, "ap_c", 1)
    #     $redis_rtb.expire(key, 2.weeks)
    #   end
    # end
    redis_rtb_hash
  end

  def self.get_buying_list_above(above_val, u_values, buying_list_key, base_item_ids)
    proc_item_ids = u_values.map {|key,val| if key.include?("_c") && val.to_i > above_val; key.gsub("_c",""); end}.compact

    old_buying_list = u_values[buying_list_key]
    buying_list = old_buying_list.to_s.split(",")

    if !buying_list.blank?
      have_to_del = []

      #remove items from buyinglist which detail is expired
      buying_list.each do |each_item|
        if !u_values.include?("#{each_item}_c") || u_values["#{each_item}_c"].to_i < above_val
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
    buying_list
  end

  def self.update_buying_list_only_housing(user_ids)
    redis_rtb_hash = {}
    source = "housing"

    user_ids.each do |user_id|
      u_key = "u:ac:plannto:#{user_id}"
      u_values = $redis.hgetall(u_key)

      existing_source = u_values["source"].to_s
      existing_source = existing_source.split(",").compact
      existing_source << source
      new_source = existing_source.uniq
      u_values["source"] = new_source.join(",")

      temp_store = {"source" => new_source.join(","), "housinglad" => Date.today.to_s}

      redis_rtb_hash.merge!("users:buyinglist:plannto:#{user_id}" => temp_store)
    end

    # Redis Rtb update
    $redis_rtb.pipelined do
      redis_rtb_hash.each do |key, val|
        $redis_rtb.hmset(key, val.flatten)
        $redis_rtb.expire(key, 3.weeks)
      end
    end
  end
end
