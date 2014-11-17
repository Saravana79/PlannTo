class FeedUrl < ActiveRecord::Base
  belongs_to :feed

  validates_uniqueness_of :url

  VALID = 1
  FUTURE = 2
  INVALID = 3

  def self.update_by_missing_records(log, process_type, count, valid_urls, invalid_urls, missing_ad)
    invalid_urls = invalid_urls.delete_if { |x| (x.blank? || x == "nil") }

    if process_type != "all"
      past_date = Date.yesterday.strftime("%Y-%-m-%-d")
      current_date = Date.today.strftime("%Y-%-m-%-d")
      set_keys = ["missingurl-#{past_date}", "missingurl-#{current_date}"]

      set_keys.each do |each_key|
        get_missing_keys_and_process_recent(each_key, count, "process_missing_url", invalid_urls)
      end
    else
      unless valid_urls.blank?
        # process for missingurl
        valid_urls = valid_urls.delete_if { |x| (x.blank? || x == "nil") }
        valid_urls.each do |each_url|
          match_url = each_url == "missingurl:*" ? "missingurl:*" : "missingurl:*#{each_url}*"
          get_missing_keys_and_process(match_url, count, "process_missing_url", invalid_urls)
        end
      end
    end

    # Process missingad
    if missing_ad.to_s == "true"
      get_missing_keys_and_process('missingad*', count, "process_missing_ad", invalid_urls)
    end

    # missing_invalid_url_keys = []
    # unless invalid_urls.blank?
    #   invalid_urls = invalid_urls.delete_if {|x| (x.blank? || x == "nil")}
    # invalid_urls.each do |each_url|
    #    collected_urls = get_missing_keys_from_redis("missingurl:*#{each_url}*")
    #    missing_invalid_url_keys << collected_urls
    # end
    # missing_invalid_url_keys = missing_invalid_url_keys.flatten
    # process_invalid_missing_url(missing_invalid_url_keys, count)
    # end

    # unless valid_urls.blank?
    #   # process for missingurl
    #   valid_urls = valid_urls.delete_if {|x| (x.blank? || x == "nil")}
    #   missingurl_keys = []
    #   valid_urls.each do |each_url|
    #     match_url =  each_url == "missingurl:*" ? "missingurl:*" : "missingurl:*#{each_url}*"
    #     collected_urls = get_missing_keys_from_redis(match_url)
    #     missingurl_keys << collected_urls
    #   end
    #   missingurl_keys = missingurl_keys.flatten
    #   missingurl_keys = missingurl_keys - missing_invalid_url_keys
    #   process_missing_url(missingurl_keys, count)
    # end

    # Process missingad
    # if missing_ad.to_s == "true"
    #   missingad_keys = get_missing_keys_from_redis('missingad*')
    #   process_missing_ad(missingad_keys, count)
    # end
  end

  def self.missing_url_process_top_list
    get_missing_keys_and_process_recent("missingurl-toplist", 0, "process_missing_url_top_list", invalid_urls=[])
  end

  def self.process_missing_url_top_list(missingurl_keys, count=0, valid_categories=["science & technology"])
    feed = Feed.where("process_type = 'missingurl'").last
    admin_user = User.where(:is_admin => true).first

    counting = 1
    greater_count = 1
    missingurl_keys = [] if missingurl_keys.blank?
    t_count = missingurl_keys.count
    missingurl_keys.each do |each_url_key|
      logger.info "#{counting} - #{t_count}"
      p "#{counting} - #{t_count}"
      counting = counting + 1
      each_url_key = "missingurl:#{each_url_key}" unless each_url_key.include?("missingurl")
      missingurl_count, feed_url_id = $redis_rtb.hmget(each_url_key, 'count', 'feed_url_id')

      greater_count = greater_count + 1
      logger.info "#{counting} - #{t_count} - #{greater_count} - #{missingurl_count} - #{feed_url_id}"
      p "#{counting} - #{t_count} - #{greater_count} - #{missingurl_count} - #{feed_url_id}"
      if feed_url_id.blank?
        missing_url = each_url_key.split("missingurl:")[1]

        check_exist_feed_url = FeedUrl.where(:url => missing_url).first
        if check_exist_feed_url.blank?
          source = ""
          if (missing_url =~ URI::regexp).blank?
            source = ""
            status = 3
          else
            begin
              source = URI.parse(URI.encode(URI.decode(missing_url))).host.gsub("www.", "")
            rescue Exception => e
              source = Addressable::URI.parse(missing_url).host.gsub("www.", "")
            end
          end

          # sources_list = Rails.cache.read("sources_list_details")
          sources_list = JSON.parse($redis_rtb.get("sources_list_details"))
          sources_list.default = "Others"
          category = sources_list[source]["categories"] rescue ""

          # check_exist_feed_url = FeedUrl.where(:url => missing_url).first
          # if check_exist_feed_url.blank?
          article_content = ArticleContent.find_by_url(missing_url)
          status = 0
          status = 1 unless article_content.blank?

          title, description, images, page_category = Feed.get_feed_url_values(missing_url)

          url_for_save = missing_url
          if url_for_save.include?("youtube.com")
            url_for_save = url_for_save.gsub("watch?v=", "video/")
          end

          if !page_category.blank?
            if !valid_categories.include?(page_category.downcase)
              status = 3
            elsif page_category.downcase == 'science & technology'
              category = "Mobile,Tablet,Camera,Laptop"
            end
          end
          # remove characters after come with space + '- or |' symbols
          # title = title.to_s.gsub(/\s(-|\|).+/, '')
          title = title.blank? ? "" : title.to_s.strip

          new_feed_url = FeedUrl.new(feed_id: feed.id, url: url_for_save, title: title.to_s.strip, category: category,
                                        status: status, source: source, summary: description, :images => images,
                                        :published_at => Time.now, :priorities => feed.priorities, :missing_count => missingurl_count, :additional_details => page_category)

          begin
            new_feed_url.save!
            feed_url, article_content = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(new_feed_url, admin_user, nil)
            feed_url.auto_save_feed_urls if feed_url.status == 0
          rescue Exception => e
            p e
          end

          $redis_rtb.hmset(each_url_key, "feed_url_id", new_feed_url.id, "count", 0) if Rails.env == "production"
        else
          ActiveRecord::Base.connection.execute("update feed_urls set missing_count=missing_count+#{missingurl_count.to_i} where id=#{check_exist_feed_url.id}")
          $redis_rtb.hmset(each_url_key, "feed_url_id", check_exist_feed_url.id, "count", 0) if Rails.env == "production"
        end
      else
        ActiveRecord::Base.connection.execute("update feed_urls set missing_count=missing_count+#{missingurl_count.to_i} where id=#{feed_url_id}")
        $redis_rtb.hmset(each_url_key, "count", 0) if Rails.env == "production"
      end

      mem_key = each_url_key.gsub("missingurl:", "")
      $redis_rtb.srem("missingurl-toplist", mem_key) if Rails.env == "production"
    end
  end

  def self.process_missing_url(missingurl_keys, count, valid_categories=["gaming", "science & technology"], process_category="recent")
    feed = Feed.where("process_type = 'missingurl'").last
    admin_user = User.where(:is_admin => true).first

    counting = 1
    greater_count = 1
    missingurl_keys = [] if missingurl_keys.blank?
    t_count = missingurl_keys.count
    missingurl_keys.each do |each_url_key|
      logger.info "#{counting} - #{t_count}"
      p "#{counting} - #{t_count}"
      counting = counting + 1
      each_url_key = "missingurl:#{each_url_key}" unless each_url_key.include?("missingurl")
      missingurl_count, feed_url_id = $redis_rtb.hmget(each_url_key, 'count', 'feed_url_id')
      if missingurl_count.to_i > count.to_i
        greater_count = greater_count + 1
        logger.info "#{counting} - #{t_count} - #{greater_count} - #{missingurl_count} - #{feed_url_id}"
        p "#{counting} - #{t_count} - #{greater_count} - #{missingurl_count} - #{feed_url_id}"
        if feed_url_id.blank?
          missing_url = each_url_key.split("missingurl:")[1]

          check_exist_feed_url = FeedUrl.where(:url => missing_url).first
          if check_exist_feed_url.blank?
            source = ""
            if (missing_url =~ URI::regexp).blank?
              source = ""
              status = 3
            else
              source = URI.parse(URI.encode(URI.decode(missing_url))).host.gsub("www.", "")
            end

            # sources_list = Rails.cache.read("sources_list_details")
            sources_list = JSON.parse($redis_rtb.get("sources_list_details"))
            sources_list.default = "Others"
            category = sources_list[source]["categories"] rescue ""

            # check_exist_feed_url = FeedUrl.where(:url => missing_url).first
            # if check_exist_feed_url.blank?
            article_content = ArticleContent.find_by_url(missing_url)
            status = 0
            status = 1 unless article_content.blank?

            title, description, images, page_category = Feed.get_feed_url_values(missing_url)

            url_for_save = missing_url
            if url_for_save.include?("youtube.com")
              url_for_save = url_for_save.gsub("watch?v=", "video/")
            end

            if !page_category.blank?
              unless valid_categories.include?(page_category.downcase)
                status = 3
                if page_category.downcase == 'science & technology'
                  category = "Mobile,Tablet,Camera,Laptop"
                end
              end
            end
            # remove characters after come with space + '- or |' symbols
            # title = title.to_s.gsub(/\s(-|\|).+/, '') #TODO: check and add it later
            # title = title.blank? ? "" : title.to_s.strip
            title = title.to_s.strip

            new_feed_url = FeedUrl.new(feed_id: feed.id, url: url_for_save, title: title.to_s.strip, category: category,
                                          status: status, source: source, summary: description, :images => images,
                                          :published_at => Time.now, :priorities => feed.priorities, :missing_count => missingurl_count, :additional_details => page_category)

            begin
              new_feed_url.save!
              feed_url, article_content = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(new_feed_url, admin_user, nil)
              feed_url.auto_save_feed_urls if feed_url.status == 0
            rescue Exception => e
              p e
            end

            $redis_rtb.hmset(each_url_key, "feed_url_id", new_feed_url.id, "count", 0) if Rails.env == "production"
          else
            ActiveRecord::Base.connection.execute("update feed_urls set missing_count=missing_count+#{missingurl_count.to_i} where id=#{check_exist_feed_url.id}")
            $redis_rtb.hmset(each_url_key, "feed_url_id", check_exist_feed_url.id, "count", 0) if Rails.env == "production"
          end
        else
          ActiveRecord::Base.connection.execute("update feed_urls set missing_count=missing_count+#{missingurl_count.to_i} where id=#{feed_url_id}")
          $redis_rtb.hmset(each_url_key, "count", 0) if Rails.env == "production"
        end

        # remove key from redis
        # $redis_rtb.del(each_url_key) if Rails.env == "production"
      elsif process_category == "all" && missingurl_count.to_i == 0
        $redis_rtb.del(each_url_key) if Rails.env == "production"
      end
    end
  end

  def self.process_missing_ad(missingad_keys, count)
    missingad_keys.each do |each_ad_key|
      missingad_count = $redis_rtb.hget(each_ad_key, 'count')
      if missingad_count.to_i > count.to_i
        missing_ad_url = each_ad_key.split("missingad:")[1]

        missing_ad_detail = MissingAdDetail.find_or_initialize_by_url(:url => missing_ad_url)

        missingad_count = missing_ad_detail.count.to_i + missingad_count.to_i unless missing_ad_detail.new_record?
        missing_ad_detail.update_attributes(:count => missingad_count.to_i)

        $redis_rtb.hset(each_ad_key, 'count', 0) if Rails.env == "production"
      end
    end
  end

  def self.get_missing_keys_from_redis(match)
    exp_val = []
    next_val = 0
    begin
      redis_val = $redis_rtb.scan(next_val, match: match, count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      exp_val << val
    end while next_val != 0

    exp_val.flatten
  end

  def self.get_missing_keys_and_process(match, count, method, invalid_urls=[])
    next_val = 0
    begin
      redis_val = $redis_rtb.scan(next_val, match: match, count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      invalid_urls.each do |each_invalid_url|
        val = val.delete_if { |each_key| each_key.include?(each_invalid_url) }
      end
      # process_missing_url(val, count)
      if method == "process_missing_url"
        FeedUrl.send(method, val, count, ["gaming", "science & technology"], "all")
      else
        FeedUrl.send(method, val, count)
      end
    end while next_val != 0
    return
  end

  def self.get_missing_keys_and_process_recent(redis_key, count, method, invalid_urls=[])
    next_val = 0
    start = 0
    begin
      redis_val = $redis_rtb.sscan(redis_key, next_val, count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      invalid_urls.each do |each_invalid_url|
        val = val.delete_if { |each_key| each_key.include?(each_invalid_url) }
      end
      # process_missing_url(val, count)
      FeedUrl.send(method, val, count)
      p "started count: #{start} - #{start * 300}"
      start += 1
    end while next_val != 0
    return
  end

  def self.get_missing_youtube_keys(count, valid_categories=[])
    next_val = 0
    loop_count = 0
    begin
      redis_val = $redis_rtb.scan(next_val, match: "missingurl:http://www.youtube.com*", count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      # process_missing_url(val, count)
      p "Loop Count => #{loop_count}"
      loop_count+=1
      FeedUrl.process_missing_url(val, count, valid_categories)
    end while next_val != 0
  end

  def self.remove_missing_keys(match)
    next_val = 0
    loop_count = 0
    begin
      redis_val = $redis_rtb.scan(next_val, match: match, count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      p "Loop Count => #{loop_count}"
      loop_count+=1
      removed_item_count = $redis_rtb.del(val) unless val.blank?
      p "removed items #{removed_item_count}"
    end while next_val != 0
  end

  def self.check_and_assign_sources_hash_to_source_category_daily()
    sources_categories = SourceCategory.find_by_sql("select distinct source from source_categories")

    source_list = sources_categories.map(&:source)

    source_condition = source_list.blank? ? " 1=1 and " : " source not in (#{source_list.map(&:inspect).join(',')}) and "
    sources = FeedUrl.where("#{source_condition} source != ''").select("distinct source")

    sources.each do |each_source|
      feed_by_sources = FeedUrl.find_by_sql("select distinct category from feed_urls where `feed_urls`.`source` = '#{each_source.source}'")
      category = "Others"
      unless feed_by_sources.blank?
        categories = feed_by_sources.map(&:category)
        categories = categories.map { |each_cat| each_cat.to_s.split(',') }
        categories = categories.flatten.uniq
        categories = categories - ['Others'] if categories.count > 1
        category = categories.join(',')
      end
      begin
        source_category = SourceCategory.new(:source => each_source.source, :categories => category)
        source_category.save!
        p source_category
      rescue Exception => e
        puts "skip if exist already"
        p e
      end
    end

    #update all source categories to cache

    SourceCategory.update_all_to_cache()
  end

  def self.clean_up_redis_keys
    #clean missingurl:*
    # remove_missing_keys("missingurl:*") #TOODO: commented

    #clean missingad:*
    remove_missing_keys("missingad:*")

    #clean spottags:*
    remove_missing_keys("spottags:*")

    #start sid_ad_detail_process
    Resque.enqueue(SidAdDetailProcess, "update_clicks_and_impressions_for_sid_ad_details", Time.zone.now, 1000)
  end

  def check_and_update_mobile_site_feed_url(param, user, remote_ip)
    url = self.url
    host = Addressable::URI.parse(url).host.downcase
    host = host.start_with?('www.') ? host[4..-1] : host
    source_category = SourceCategory.where(:source => host).last
    if !source_category.blank? && !source_category.prefix.blank?
      prefix = source_category.prefix
      processed_host = host.include?(prefix) ? host.gsub(prefix, '') : prefix+host
      processed_url = url.gsub(host, processed_host)

      new_feed_url = FeedUrl.where(:url => processed_url, :status => 0)

      unless new_feed_url.blank?
        new_param = param
        new_param.merge!(:feed_url_id => new_feed_url.id)
        new_param[:article_content].merge!(:url => new_feed_url.url)
        Resque.enqueue(ArticleContentProcess, "create_article_content", Time.zone.now, new_param.to_json, user.blank? ? nil : user.id, remote_ip)
        new_feed_url.update_attributes(:status => 1, :default_status => 6)
      end
    end
  end

  def check_and_update_sub_type(article)
    source_hash = $redis_rtb.get("sources_list_details")
    unless source_hash.blank?
      source_list = JSON.parse(source_hash)
      host = Addressable::URI.parse(self.url).host.downcase
      updated_host = host.start_with?('www.') ? host[4..-1] : host
      source_details = source_list[updated_host]
      if !source_details.blank? && !source_details["check_details"].blank?
        check_details = source_details["check_details"].to_s.split("~").map {|each_val| each_val.split("^")}.flatten.map(&:strip)
        check_details = Hash[*check_details]
        title = article.title
        return_val = ""
        changed_title = article.title
        check_details.each do |key, value|
          if changed_title.include?(key)
            if value.blank? || value == "empty" || value == "any"
              if value == "any"
                changed_title = changed_title.to_s.gsub(/#{key}.*/, "")
              else
                changed_title = changed_title.to_s.gsub(key, "")
              end
              return_val = article.find_subtype(changed_title) if return_val.blank?
            elsif return_val.blank?
              changed_title = changed_title.to_s.gsub(key, "")
              return_val = value
            else
              changed_title = changed_title.to_s.gsub(key, "")
            end
          end
        end
        return return_val, changed_title
      end
    end
    return nil, article.title
  end

  def auto_save_feed_urls(force_default_save=false)
    feed_url = self
    article = ArticleContent.new(:url => feed_url.url, :created_by => 1)
    title_info = feed_url.title
    if title_info.include?("|")
      title_info = title_info.to_s.slice(0..(title_info.index('|'))).gsub(/\|/, "").strip
    end
    article.title = title_info
    article.sub_type = article.find_subtype(article.title)
    sub_type, title_for_search = feed_url.check_and_update_sub_type(article)
    article.sub_type = sub_type unless sub_type.blank?
    article.description = feed_url.summary
    images = feed_url.images.split(",")
    article.thumbnail = images.first if images.count > 0

    if article.url.include?("youtube.com")
      article.url = article.url.gsub("watch?v=", "video/")
      video_id = VideoContent.video_id(article.url)
      article.field4 = video_id
      article.video = true
    end


    article.sub_type = "Others" if article.sub_type.blank?

    if article.sub_type == "Others"
      host = Addressable::URI.parse(article.url).host
      url_for_search = article.url.gsub(host, "")
      subtype_from_url = article.find_subtype(url_for_search)
      article.sub_type = subtype_from_url unless subtype_from_url.blank?
    end
    article_content = article

    search_params = {}
    search_params.merge!(:term => title_for_search, :search_type => "ArticleContent", :category => feed_url.category, :ac_sub_type => article.sub_type)

    results, selected_list, list_scores, auto_save = Product.call_search_items_by_relavance(search_params)
    selected_list = selected_list.uniq
    auto_save = "false" if selected_list.blank?
    auto_save = "false" if article.sub_type == "Comparisons" && selected_list.count < 2

    actual_title = feed_url.created_at < 2.weeks.ago ? feed_url.title : ""

    if auto_save == "false" && (force_default_save || !actual_title.blank?)
      if !selected_list.blank? && article.sub_type == "Others"
        auto_save = "true"
      else
        actual_title = feed_url.title if actual_title.blank?
        host_without_www = Item.get_host_without_www(article.url)
        selected_list = FeedUrl.get_selected_list_for_old_data(actual_title, host_without_www)
        selected_list = selected_list.compact.uniq
        auto_save = "true" if !selected_list.blank?
      end
    end

    if auto_save == "true" && !selected_list.blank?
      old_count = selected_list.count
      res_with_type = {}; results.each {|result| res_with_type.merge!(result[:id] => result[:type])}
      selected_list.delete_if {|each_val| res_with_type[each_val] == "Manufacturer"}
      auto_save = "false" if selected_list.count != old_count
    end

    if auto_save == "true"
      param = {}
      article_item_ids = selected_list.join(",")
      unless article_item_ids.blank?
        param.merge!(:feed_url_id => feed_url.id, :default_item_id => "", :submit_url => "submit_url",
                     :article_content => { :itemtype_id => article_content.itemtype_id, :type => article_content.type, :thumbnail => article_content.thumbnail,
                                           :title => article_content.title, :url => article.url, :sub_type => article_content.sub_type, :description => article_content.description },
                     :share_from_home => "", :detail => "", :articles_item_id => article_item_ids, :external => "true", :score => "0")

        param.merge!(:score => article_content.field1) if article_content.sub_type == ArticleCategory::REVIEWS
        Resque.enqueue(ArticleContentProcessAuto, "create_article_content", Time.zone.now, param.to_json, 1, "")
        feed_url.update_attributes!(:status => 1, :default_status => 5) #TODO: auto save status as 5
      end
    end
    auto_save
  end

  def self.get_selected_list_for_old_data(title_for_check, host_without_www)
    title_for_check = title_for_check.to_s.downcase
    return_val = ""
    matching_text = [["mobile", "phone"], ["tablet", "pad"], ["car"], ["bike"], ["apps", "app "], ["games", "game", "gaming"], ["camera", "dslr", "photography"], ["laptop", "ultratop", "notebook"], ['lens'], ['tv', 'television']]
    matching_category_ids = [configatron.root_level_mobile_id, configatron.root_level_tablet_id, configatron.root_level_car_id, configatron.root_level_bike_id, configatron.root_level_app_id, configatron.root_level_game_id, configatron.root_level_camera_id, configatron.root_level_laptop_id, configatron.root_level_lens_id, configatron.root_level_television_id]

    selected_values = []
    matching_text.each_with_index do |each_text_arr, index|
      each_text_arr.each do |each_text|
        if title_for_check.include?(each_text)
          selected_values << matching_category_ids[index]
        end
      end
    end
    if selected_values.blank?
      sources_list = JSON.parse($redis_rtb.get("sources_list_details"))
      categories = sources_list[host_without_www]["categories"] rescue ""
      splt_categories = categories.split(",").map(&:strip)
      selected_values = splt_categories.map {|d| Item.get_root_level_id(d)}
    end
    selected_values
  end

  def self.automated_feed_process
    feed_urls = FeedUrl.where("status = 0 and (created_at < '#{2.weeks.ago.utc}' and created_at > '#{2.weeks.ago.utc + 1.day}') or created_at > '#{2.days.ago.utc}'")
    sources_list = JSON.parse($redis_rtb.get("sources_list_details"))

    feed_urls.each do |feed_url|
      host = Item.get_host_without_www(feed_url.url)
      if sources_list[host]["site_status"] == false
        feed_url.update_attributes!(:status => FeedUrl::INVALID)  #mark as invalid based on url
      else
        begin
          feed_url.auto_save_feed_urls
        rescue Exception => e
          p e.backtrace
        end
      end
    end
  end
end
