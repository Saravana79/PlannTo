class CookieMatch < ActiveRecord::Base
  validates_uniqueness_of :plannto_user_id

  scope :find_user, lambda {|plannto_user_id| where("plannto_user_id = '#{plannto_user_id}' and updated_at > '#{14.days.ago}'")}
  scope :find_user_by_source, lambda {|plannto_user_id, source| where("plannto_user_id = '#{plannto_user_id}' and match_source like '%#{source}%' and updated_at > '#{14.days.ago}'")}

  def self.check_cookie_user_exists?(plannto_user_id)
    matches = find_user(plannto_user_id)
    !matches.blank?
  end

  def self.enqueue_cookie_matching(param, plannto_user_id)
    ref_url = (param["ref_url"].include?("%3A%2F%2F") ?  CGI.unescape(param["ref_url"]) : param["ref_url"]) rescue ""
    source_source_url = (param["source_source_url"].include?("%3A%2F%2F") ?  CGI.unescape(param["source_source_url"]) : param["source_source_url"]) rescue ""
    param["source"] ||= "google"
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => ref_url, "source" => param["source"], "source_source_url" => source_source_url}

    if ["google_pixel", "mysmartprice"].exclude?(param["source"])
      Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
    end
  end

  def self.enqueue_pixel_matching(param, plannto_user_id)
    u_key = "u:ac:#{param["google_gid"]}"
    # u_values = $redis.hgetall(u_key)
    google_ula = ""

    # if !u_values.blank?
    #   valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => "", "source" => "google_pixel"}
    #   Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
    #   # google_ula = "&google_ula=8326120&google_ula=8365600"
    #   google_ula = "&google_ula=8326120"
    # end

    plannto_user_detail = PUserDetail.where(:gid => param["google_gid"]).to_a.last

    if !plannto_user_detail.blank?
      valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => "", "source" => "google_pixel"}
      Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
      google_ula = "&google_ula=8326120"
    else
      google_ula = "&google_ula=58712800"
    end

    google_ula
  end

  def self.process_cookie_matching(param)
    param["source"] ||= "google"
    cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(param["plannto_user_id"])
    if cookie_match.new_record?
      source = param["source"]
    else
      source = cookie_match.match_source.to_s.split(",") + [param["source"]]
      source = source.uniq.join(",")
    end
    cookie_match.update_attributes(:google_user_id => param["google_id"], :match_source => source, :google_mapped => true)

    $redis_rtb.pipelined do
      $redis_rtb.set("cm:#{param['google_id']}", param["plannto_user_id"])
      $redis_rtb.expire("cm:#{param['google_id']}", 1.weeks)
    end

    if !param["ref_url"].blank?
      user_access_detail = UserAccessDetail.find_or_initialize_by_plannto_user_id_and_ref_url_and_source(param["plannto_user_id"], param["ref_url"], param["source"])
      user_access_detail.save
    end
  end

  def self.bulk_process_cookie_matching()
    if $redis.get("bulk_process_cookie_matching_is_running").to_i == 0
      $redis.set("bulk_process_cookie_matching_is_running", 1)
      length = $redis.llen("resque:queue:cookie_matching_process")
      expire_time = length/100000
      expire_time = expire_time.to_i == 0 ? 30.minutes : expire_time.to_i.hour
      $redis.expire("bulk_process_cookie_matching_is_running", expire_time)
      count = length

      skip_urls = ["http://www.mysmartprice.com/msp/search/search.php?category=", "http://www.mysmartprice.com/out/sendtostore.php?top_category=", "http://www.mysmartprice.com/accessories/", "http://www.mysmartprice.com/appliance/", "/pricelist/", "http://coupons.mysmartprice.com/", "http://www.mysmartprice.com/m/custom_list.php?", "http://www.mysmartprice.com/deals/", "http://www.mysmartprice.com/men/", "http://www.mysmartprice.com/kids/", "http://www.mysmartprice.com/out/sendtostore.php?html5=1", "http://www.mysmartprice.com/out/sendtostore.php?dealid=", "http://www.mysmartprice.com/care/", "http://www.mysmartprice.com/m/search.php"]
      existing_pattern = ["mspid=<pattern_val>", "-msp=<pattern_val>", "-mst<pattern_val>-other"]

      # source_categories = JSON.parse($redis.get("source_categories_pattern"))
      # source_categories.default = {"pattern" => ""}

      begin
        cookie_details = $redis.lrange("resque:queue:cookie_matching_process", 0, 2000)
        cookies_arr = []
        user_access_details = []

        cookie_details.each do |cookie_detail|
          count -= 1
          begin
            cookie_detail = JSON.parse(cookie_detail)["args"][1]
            cookie_detail["source"] ||= "google"
            ref_url = cookie_detail.delete("ref_url")
            source_source_url = cookie_detail.delete("source_source_url")
            cookies_arr << cookie_detail
            if !ref_url.blank?
              param = {"plannto_user_id" => cookie_detail["plannto_user_id"], "ref_url" => ref_url, "source" => cookie_detail["source"], "source_source_url" => source_source_url}
              user_access_details << param
            end
          rescue Exception => e
            p "There was problem while running cookie_match => #{e.backtrace}"
          end
          p "Remaining CookieMatch Count - #{count}"
        end

        # ActiveRecord::Base.transaction do
        #   cookies_arr.each do |cookie_detail|
        #     cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookie_detail["plannto_user_id"])
        #     cookie_match.update_attributes(:google_user_id => cookie_detail["google_id"], :match_source => cookie_detail["source"])
        #   end
        # end

        imported_values = []
        cookies_arr.each do |cookie_detail|
          cookie_match = CookieMatch.new(:plannto_user_id => cookie_detail["plannto_user_id"], :google_user_id => cookie_detail["google_id"], :match_source => cookie_detail["source"], :google_mapped => true)
          imported_values << cookie_match
        end

        imported_values = imported_values.reverse.uniq(&:plannto_user_id)

        result = CookieMatch.import(imported_values)

        #TODO: have to delete duplicate records
        # result.failed_instances.each do |cookie_detail|
        #   cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookie_detail.plannto_user_id)
        #   cookie_match.update_attributes(:google_user_id => cookie_detail.google_user_id, :match_source => cookie_detail.match_source)
        # end

        $redis_rtb.pipelined do
          imported_values.each do |cookie_detail|
            $redis_rtb.set("cm:#{cookie_detail.google_user_id}", cookie_detail.plannto_user_id)
            $redis_rtb.expire("cm:#{cookie_detail.google_user_id}", 1.weeks)
          end
        end

        user_access_details_count = user_access_details.count
        user_access_details_import = []
        redis_rtb_hash = {}
        plannto_user_detail_hash = {}
        housing_user_access_details_user_ids = []
        user_access_details.each do |user_access_detail|
          begin
            p "Remaining UserAccessDetail Count - #{user_access_details_count}"
            user_access_details_count-=1
            new_user_access_detail = UserAccessDetail.new(:plannto_user_id => user_access_detail["plannto_user_id"], :ref_url => user_access_detail["ref_url"], :source => user_access_detail["source"])
            # new_user_access_detail = UserAccessDetail.find_or_initialize_by_plannto_user_id_and_ref_url_and_source(user_access_detail["plannto_user_id"], user_access_detail["ref_url"], user_access_detail["source"])
            ref_url = new_user_access_detail.ref_url.to_s
            including_skip_val = skip_urls.any? { |word| ref_url.include?(word) }

            next if including_skip_val

            # user_access_details_import << new_user_access_detail

            if new_user_access_detail.source == "housing"
              housing_user_access_details_user_ids << new_user_access_detail.plannto_user_id
              next
            end

            msp_id = CookieMatch.get_mspid_from_existing_pattern(existing_pattern, ref_url)
            if ref_url.include?("cardekho")
              # site_condition = new_user_access_detail.source == "mysmartprice" ? " and site='26351'" : ""
              item_detail_other = ItemDetailOther.where(:url => ref_url).last

              if !item_detail_other.blank?
                user_id = new_user_access_detail.plannto_user_id
                type = "Resale"

                itemtype_id = item_detail_other.itemtype_id rescue ""

                item_ids = item_detail_other.item_detail_other_mappings.map(&:item_id).join(",").to_s rescue ""
                redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, new_user_access_detail.source, itemtype_id)
                redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
                plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
              else
                item_detail_other = ItemDetailOther.update_item_detail_other_for_cardekho(ref_url)

                user_id = new_user_access_detail.plannto_user_id
                type = "Resale"

                itemtype_id = item_detail_other.itemtype_id rescue ""

                item_ids = item_detail_other.item_detail_other_mappings.map(&:item_id).join(",").to_s rescue ""
                redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, new_user_access_detail.source, itemtype_id)
                redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
                plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
              end
            elsif user_access_detail["source"] == "housing"
              user_id = new_user_access_detail.plannto_user_id
              type = "Reviews"

              itemtype_id = item_detail_other.itemtype_id rescue ""

              item_ids = ""
              redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, user_access_detail["source"], itemtype_id)
              plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
            elsif user_access_detail["source"] == "autoportal"
              user_id = new_user_access_detail.plannto_user_id
              type = "Reviews"
              par_url = ref_url.to_s.split("/")- [ref_url.to_s.split("/").last]
              par_url = par_url.join("/") + "/" + "%"

              # item_details = Itemdetail.where("url like '#{par_url}' and site=75798")

              item_details = Itemdetail.find_by_sql("SELECT distinct(itemid),i.itemtype_id as item_type_id FROM itemdetails inner join items i on i.id = itemdetails.itemid WHERE itemdetails.url like '#{par_url}' and site='75798' ORDER BY itemdetails.item_details_id DESC")

              item_details_by_itemtype_ids = item_details.group_by {|x| x.item_type_id}

              item_details_by_itemtype_ids.each do |key, val|
                itemtype_id = key
                item_ids = val.map(&:itemid).join(",")
                redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, user_access_detail["source"], itemtype_id, user_access_detail["source_source_url"])
                plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
              end
            elsif !msp_id.blank?
              site_condition = new_user_access_detail.source == "mysmartprice" ? " and site='26351'" : ""
              item_detail = Itemdetail.find_by_sql("SELECT itemid,i.itemtype_id FROM itemdetails inner join items i on i.id = itemdetails.itemid WHERE itemdetails.additional_details = '#{msp_id}' #{site_condition} ORDER BY itemdetails.item_details_id DESC LIMIT 1").first

              unless item_detail.blank?
                user_id = new_user_access_detail.plannto_user_id
                type = "Vendor"

                if ref_url.include?("/m/single.php") || ref_url.include?("/m/single_techspec.php")
                  type = "Spec"
                end

                itemtype_id = item_detail.itemtype_id rescue ""

                item_ids = item_detail.itemid.to_s rescue ""
                redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, new_user_access_detail.source, itemtype_id)
                redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
                plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
              end
            else
              article_content = ArticleContent.find_by_sql("select sub_type,group_concat(icc.item_id) all_item_ids, ac.id, itemtype_id from article_contents ac inner join contents c on ac.id = c.id
inner join item_contents_relations_cache icc on icc.content_id = ac.id
where url = '#{ref_url}' group by ac.id").first

              unless article_content.blank?
                #TODO: have to continue from here
                user_id = new_user_access_detail.plannto_user_id
                type = article_content.sub_type
                item_ids = article_content.all_item_ids.to_s rescue ""

                #plannto user details
                itemtype_id = article_content.itemtype_id

                redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, ref_url, type, item_ids, source_categories={}, new_user_access_detail.source, itemtype_id)
                redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
                plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
              end
            end
          rescue Exception => e
            p "There was problem in UserAccssDetail => #{e}"
            p "There was problem in UserAccssDetail => #{e.backtrace}"
          end
        end

        # Redis Rtb update
        $redis_rtb.pipelined do
          redis_rtb_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.hincrby(key, "ap_c", 1)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        $redis_rtb.pipelined do
          plannto_user_detail_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        # UserAccessDetail.update_buying_list_only_housing(housing_user_access_details_user_ids)

        # UserAccessDetail.import(user_access_details_import)

        $redis.ltrim("resque:queue:cookie_matching_process", cookie_details.count, -1)
        length = length - cookie_details.count
        p "*********************************** Remaining CookieMatch Length - #{length} **********************************"
      end while length > 0
      $redis.set("bulk_process_cookie_matching_is_running", 0)
    end
  end

  def self.get_mspid_from_existing_pattern(existing_pattern, ref_url)
    existing_pattern.each do |pattern|
      msp_id = FeedUrl.get_value_from_pattern(ref_url, pattern)
      return msp_id if !msp_id.blank? && msp_id.to_s.is_an_integer?
    end
    return nil
  end

  def self.un_match_cookie(user_id)
    u_key = "u:ac:plannto:#{user_id}"
    u_values = $redis.hgetall(u_key)

    if !u_values.blank?
      existing_source = u_values["source"].to_s
      existing_source = existing_source.split(",").compact
      existing_source.delete("housing")
      new_source = existing_source.uniq
      u_values["source"] = new_source.join(",")

      $redis.pipelined do
        $redis.hmset(u_key, u_values.flatten)
        $redis.expire(u_key, 3.weeks)
      end
    end

    key = "users:buyinglist:plannto:#{user_id}"
    rtb_values = $redis_rtb.hgetall(key)

    if !rtb_values.blank?
      existing_source = rtb_values["source"].to_s
      existing_source = existing_source.split(",").compact
      existing_source.delete("housing")
      new_source = existing_source.uniq
      rtb_values["source"] = new_source.join(",")
      rtb_values.delete("housinglad")

      $redis_rtb.pipelined do
        $redis_rtb.hmset(key, rtb_values.flatten)
        $redis_rtb.expire(key, 3.weeks)
      end
    end
  end

end