class UserAccessDetail < ActiveRecord::Base

  # after_save :update_buying_list_in_redis

  # def update_buying_list_in_redis(source_categories=nil)
  #   article_content = ArticleContent.where(:url => ref_url).first
  #
  #   unless article_content.blank?
  #     user_id = plannto_user_id
  #     type = article_content.sub_type
  #     item_ids = article_content.item_ids.join(",") rescue ""
  #     UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories, source)
  #   end
  # end

  def self.update_buying_list(user_id, url, type, item_ids,source_categories, source="google", itemtype_id=nil, ss_url=nil)
    # user_id, url, type, item_ids, advertisement_id = each_user_val.split("<<")
    agg_info = {}
    # base_item_ids = Item.get_base_items_from_config()
    # if source_categories.blank?
    #   source_categories = SourceCategory.get_source_category_with_paginations()
    # end
    redis_rtb_hash = {}
    plannto_user_detail_hash = {}
    plannto_autoportal_hash = {}

    already_exist = Item.check_if_already_exist_in_user_visits(source_categories, user_id, url, url_prefix="users:last_visits:plannto")

    p "========================= already_exist => #{already_exist} ========================="

    rk = 0
    cookie_matches_plannto_ids = []

    if already_exist == false

      case type
        when "Reviews", "Spec", "Photo"
          rk = 10
        when "Comparisons"
          rk = 5
        when "Lists", "Others"
          rk = 2
        when "Vendor"
          rk = 5
      end

      if source == "housing" #item_ids.blank?
        item_ids = "35284,35236"
        itemtype_id = 33
        rk = 5
      end

      resale = type == ArticleCategory::ReSale ? true : false

      item_ids = item_ids.to_s.split(",")
      if item_ids.count < 10

        plannto_user_detail = PUserDetail.where(:pid => user_id).to_a.last

        if (!plannto_user_detail.blank? && plannto_user_detail.gid.blank?)
          cookie_match = CookieMatch.where(:plannto_user_id => user_id).last
          if !cookie_match.blank? && !cookie_match.google_user_id.blank?
            plannto_user_detail.gid = cookie_match.google_user_id
            # plannto_user_detail.save!
          end
        elsif plannto_user_detail.blank?
          plannto_user_detail = PUserDetail.new(:pid => user_id)
          cookie_match = CookieMatch.where(:plannto_user_id => user_id).last
          if !cookie_match.blank? && !cookie_match.google_user_id.blank?
            plannto_user_detail.gid = cookie_match.google_user_id
          end
          # plannto_user_detail.save!
        end

        i_type = nil
        if !plannto_user_detail.blank?
          #plannto user details

          if !itemtype_id.blank?
            i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id, :r => resale).last
            new_m_agg_info = ""

            if resale == true
              agg_info = {"#{itemtype_id}:r" => 1}
              new_m_agg_info = "#{itemtype_id}:r:1"
            else
              agg_info = {"#{itemtype_id}" => 1}
              new_m_agg_info = "#{itemtype_id}:1"
            end

            if i_type.blank?
              # plannto_user_detail.i_types << IType.new(:itemtype_id => itemtype_id, :lu => [url].compact, :r => resale, :fad => Date.today, :ssu => [ss_url].compact)
              # i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id, :r => resale).last

              # plannto_user_detail.i_types << IType.new(:itemtype_id => itemtype_id, :lu => [url].compact, :r => resale, :fad => Date.today, :ssu => [ss_url].compact)
              i_type = IType.new(:itemtype_id => itemtype_id, :lu => [url].compact, :r => resale, :fad => Date.today, :ssu => [ss_url].compact)
            else
              lu = i_type.lu
              lu = lu.to_a
              lu << url
              i_type.lu = lu.compact.uniq
              i_type.r = resale
              # ssu = i_type.ssu
              # ssu = ssu.to_a
              # ssu << ss_url
              # i_type.ssu = ssu.compact.uniq
              # i_type.save!
            end
          end


          if url.to_s.include?("autoportal")
            ci_ids = i_type.ci_ids
            ci_ids = ci_ids.blank? ? item_ids : (ci_ids + item_ids)
            ci_ids = ci_ids.map(&:to_i).compact.uniq
            i_type.ci_ids = ci_ids
            i_type.lcd = Date.today
            i_type.source = "autoportal"

            ssu = i_type.ssu
            ssu = ssu.to_a
            ssu << ss_url
            i_type.ssu = ssu.compact.uniq

            # i_type.save! if !i_type.new_record?

            # ubl:pl:<userid>:<itemtye>

            #TODO: trying to save as bulk in redis rtb
            autoportal_key = "ubl:pl:#{plannto_user_detail.pid}:#{itemtype_id}"
            # $redis_rtb.pipelined do
            #   $redis_rtb.hmset(autoportal_key, ["source", "autoportal", "click_item_ids", ci_ids.join(",")])
            #   $redis_rtb.expire(autoportal_key, 2.weeks)
            # end

            plannto_autoportal_hash.merge!(autoportal_key => {"source" => "autoportal", "click_item_ids" => ci_ids.join(",")})
          end

          plannto_user_detail_hash_new, resale_val = plannto_user_detail.update_additional_details(url)
          plannto_user_detail_hash_new.values.first.merge!(agg_info) if !agg_info.blank? && !plannto_user_detail_hash_new.blank?
          plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)

          if !new_m_agg_info.blank?
            m_agg_info = plannto_user_detail.ai.to_s
            m_agg_info_arr = m_agg_info.split(",")
            m_agg_info_arr << new_m_agg_info
            plannto_user_detail.ai = m_agg_info_arr.uniq.join(",")
          end

          plannto_user_detail.skip_duplicate_update = true
          plannto_user_detail.save!

          cookie_matches_plannto_ids << plannto_user_detail.pid #TODO: have to implement cookie match process
        end

        # add_fad = u_values.blank? ? true : false
        #
        # # Remove expired items from user details
        # u_values.each do |key,val|
        #   if key.include?("_la") && val.to_date < 2.weeks.ago.to_date
        #     item_id = key.gsub("_la", "")
        #     u_values.delete("#{item_id}_c")
        #     u_values.delete("#{item_id}_la")
        #   end
        # end
        #
        # # incrby count for items
        # item_ids.each do |each_key|
        #   if u_values["#{each_key}_c"].blank?
        #     u_values["#{each_key}_c"] = rk
        #     u_values["#{each_key}_la"] = Date.today.to_s
        #   else
        #     old_rk = u_values["#{each_key}_c"]
        #     u_values["#{each_key}_c"] = old_rk.to_i + rk
        #     u_values["#{each_key}_la"] = Date.today.to_s
        #   end
        # end
        #
        # # Above 30 Ranking
        # buying_list = get_buying_list_above(30, u_values, "buyinglist", base_item_ids)
        #
        # # Above 20 Ranking
        # buying_list_20 = get_buying_list_above(20, u_values, "buyinglist_20", base_item_ids)
        #
        #
        # #buying soon check
        # top_sites = ["savemymoney.com", " couponrani.com", "mysmartprice.com", "findyogi.com", "findyogi.in", "smartprix.com", "pricebaba.com"]
        # host = Item.get_host_without_www(url)
        # bs = top_sites.include?(host)
        #
        # # if !old_buying_list.blank? || !buying_list.blank?
        #   u_values["buyinglist"] = buying_list.join(",")
        #   u_values["buyinglist_20"] = buying_list_20.join(",")
        #   existing_source = u_values["source"].to_s
        #   existing_source = existing_source.split(",").compact
        #   existing_source << source
        #   new_source = existing_source.uniq
        #   u_values["source"] = new_source.join(",")
        #   items_hash = u_values.select {|k,_| k.include?("_c")}
        #   items_count = items_hash.count
        #   all_item_ids = Hash[items_hash.sort_by {|_,v| v.to_i}.reverse].map {|k,_| k.gsub("_c","")}.compact

          #plannto user details
          p i_type

          if !i_type.blank?
            if !i_type.new_record?
              removed_item_ids = i_type.m_items.where(:lad.lte => 1.month.ago).map(&:item_id)
              existing_item_ids = i_type.m_items.map(&:item_id)
              arrival_item_ids = item_ids.map(&:to_i)

              removed_item_ids = removed_item_ids - arrival_item_ids

              common_item_ids = arrival_item_ids & existing_item_ids

              new_item_ids = arrival_item_ids - common_item_ids

              if !removed_item_ids.blank?
                removed_item_ids.each do |item_id|
                  exp_item = i_type.m_items.where(:item_id => item_id).last
                  exp_item.destroy
                end
              end

              if !new_item_ids.blank?
                new_item_ids.each do |item_id|
                  # lad = u_values["#{item_id}_la"].to_date
                  # rk = u_values["#{item_id}_c"]
                  i_type.m_items << MItem.new(:item_id => item_id, :lad => Date.today, :rk => rk)
                end
              end

              if !common_item_ids.blank?
                common_item_ids.each do |item_id|
                  m_item = i_type.m_items.where(:item_id => item_id).last
                  if !m_item.blank?
                    m_item.lad = Date.today
                    m_item.rk = m_item.rk.to_i + rk.to_i
                    m_item.save!
                  end
                end
              end
              i_type.save!
            else
              new_item_ids = item_ids.map(&:to_i)

              if !new_item_ids.blank?
                new_item_ids.each do |item_id|
                  # lad = u_values["#{item_id}_la"].to_date
                  # rk = u_values["#{item_id}_c"]
                  i_type.m_items << MItem.new(:item_id => item_id, :lad => Date.today, :rk => rk)
                end
              end
              plannto_user_detail.i_types << i_type
            end

            #Update redis_rtb from plannto_user_detail
            if !plannto_user_detail.blank?
              if plannto_user_detail.pid.blank?
                user_id_for_key = plannto_user_detail.gid.to_s
                if resale != true
                  pud_redis_rtb_hash_key = "ubl:#{user_id_for_key}:#{i_type.itemtype_id}"
                else
                  pud_redis_rtb_hash_key = "ubl:#{user_id_for_key}:#{i_type.itemtype_id}:resale"
                end
              else
                user_id_for_key = plannto_user_detail.pid.to_s
                if resale != true
                  pud_redis_rtb_hash_key = "ubl:pl:#{user_id_for_key}:#{i_type.itemtype_id}"
                else
                  pud_redis_rtb_hash_key = "ubl:pl:#{user_id_for_key}:#{i_type.itemtype_id}:resale"
                end
              end

              if !user_id.blank?
                item_ids = i_type.m_items.sort_by {|each_val| each_val.rk.to_i}.reverse.map(&:item_id).uniq.join(",")
                high_score = i_type.m_items.map {|each_val| each_val.rk.to_i}.max
                tot_count = i_type.m_items.count
                pud_redis_rtb_hash_values = {"item_ids" => item_ids, "high_score" => high_score, "tot_count" => tot_count, "lad" => Date.today.to_s}
                plannto_user_detail_hash.merge!(pud_redis_rtb_hash_key => pud_redis_rtb_hash_values)
              end
            end
          end


        #   all_item_ids = all_item_ids.join(",")
        #   temp_store = {"item_ids" => u_values["buyinglist"], "item_ids_20" => u_values["buyinglist_20"], "count" => items_count, "all_item_ids" => all_item_ids, "lad" => Date.today.to_s, "source" => new_source.join(",")}
        #   temp_store.merge!("bs" => bs, "bsd" => Date.today.to_s) if bs
        #   temp_store = temp_store.merge("fad" => Date.today.to_s) if add_fad
        #   redis_rtb_hash.merge!("users:buyinglist:plannto:#{user_id}" => temp_store)
        # # end
        #
        # begin
        #   if u_values.blank?
        #     del_key = "users:buyinglist:plannto:#{user_id}"
        #     $redis.del(u_key)
        #     $redis_rtb.del(del_key)
        #     redis_rtb_hash.delete(del_key)
        #   else
        #     $redis.pipelined do
        #       $redis.hmset(u_key, u_values.flatten)
        #       $redis.expire(u_key, 3.weeks)
        #     end
        #   end
        # rescue Exception => e
        #   p "Problems while hmset: Args:-"
        #   p u_key
        #   p u_values
        #   p u_values.flatten
        #   p e
        # end
      end
    end

    p "-------------------------------- CookieMatch In User Access Detail ------------------------------"

    if !cookie_matches_plannto_ids.compact!.blank?
      begin
        cookie_matches = CookieMatch.where(:plannto_user_id => cookie_matches_plannto_ids)
        cookie_matches.update_all(:updated_at => Time.now)

        $redis_rtb.pipelined do
          cookie_matches.each do |cookie_match|
            if !cookie_match.google_user_id.blank? && !cookie_match.plannto_user_id.blank?
              $redis_rtb.set("cm:#{cookie_match.google_user_id}", cookie_match.plannto_user_id)
              $redis_rtb.expire("cm:#{cookie_match.google_user_id}", 1.weeks)
            end
          end
        end
      rescue Exception => e
        p "Error processing cookie match"
      end
    end

    # $redis_rtb.pipelined do
    #   redis_rtb_hash.each do |key, val|
    #     $redis_rtb.hmset(key, val.flatten)
    #     $redis_rtb.hincrby(key, "ap_c", 1)
    #     $redis_rtb.expire(key, 2.weeks)
    #   end
    # end
    return redis_rtb_hash, plannto_user_detail_hash, plannto_autoportal_hash
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

      $redis.pipelined do
        $redis.hmset(u_key, u_values.flatten)
        $redis.expire(u_key, 3.weeks)
      end
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
