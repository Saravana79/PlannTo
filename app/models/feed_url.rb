class FeedUrl < ActiveRecord::Base
  belongs_to :feed

  def self.update_by_missing_records(log, count, valid_urls, invalid_urls, missing_ad)
    # separate missingurl and missingad
    # missingurl_keys = []
    # missingad_keys = []
    # missing_keys.each do |each_key|
    #   if each_key.include?("missingurl:")
    #     missingurl_keys << each_key
    #   elsif each_key.include?("missingad")
    #     missingad_keys << each_key
    #   end
    # end

    unless invalid_urls.blank?
      invalid_urls = invalid_urls.delete_if {|x| (x.blank? || x == "nil")}
      missing_invalid_url_keys = []
      invalid_urls.each do |each_url|
         collected_urls = get_missing_keys_from_redis("missingurl*#{each_url}*")
         missing_invalid_url_keys << collected_urls
      end
      missing_invalid_url_keys = missing_invalid_url_keys.flatten
      process_invalid_missing_url(missing_invalid_url_keys, count)
    end

    unless valid_urls.blank?
      # process for missingurl
      valid_urls = valid_urls.delete_if {|x| (x.blank? || x == "nil")}
      missingurl_keys = []
      valid_urls.each do |each_url|
        match_url =  each_url == "missingurl*" ? "missingurl*" : "missingurl*#{each_url}*"
        collected_urls = get_missing_keys_from_redis(match_url)
        missingurl_keys << collected_urls
      end
      missingurl_keys = missingurl_keys.flatten
      process_missing_url(missingurl_keys, count)
    end

    # Process missingad
    if missing_ad.to_s == "true"
      missingad_keys = get_missing_keys_from_redis('missingad*')
      process_missing_ad(missingad_keys, count)
    end
  end

  def self.process_invalid_missing_url(missing_invalid_url_keys, count)
    feed = Feed.where("process_type = 'missingurl'").last
    missing_invalid_url_keys.each do |each_url_key|
      missingurl_count, feed_url_id = $redis_rtb.hmget(each_url_key, 'count', 'feed_url_id')
      if missingurl_count.to_i > count.to_i
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

            new_feed_url = FeedUrl.create(feed_id: feed.id, url: missing_url, title: "", category: "Others",
                                          status: 3, source: source, summary: "", :images => "",
                                          :published_at => Time.now, :priorities => feed.priorities, :missing_count => missingurl_count)

            $redis_rtb.hmset(each_url_key, "feed_url_id", new_feed_url.id, "count", 0) if Rails.env == "production"
          end
        else
          $redis_rtb.hset(each_url_key, "count", 0) if Rails.env == "production"
        end
      end
    end
  end

  def self.process_missing_url(missingurl_keys=[], count)
    feed = Feed.where("process_type = 'missingurl'").last
    missingurl_keys.each do |each_url_key|
      missingurl_count, feed_url_id = $redis_rtb.hmget(each_url_key, 'count', 'feed_url_id')
      if missingurl_count.to_i > count.to_i
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

            category = "Others"

            if source != ""
              feed_by_sources = FeedUrl.find_by_sql("select distinct category from feed_urls where `feed_urls`.`source` = '#{source}'")
              unless feed_by_sources.blank?
                categories = feed_by_sources.map(&:category)
                categories = categories.map { |each_cat| each_cat.split(',') }
                category = categories.flatten.uniq.join(',')
              end
            end

            # check_exist_feed_url = FeedUrl.where(:url => missing_url).first
            # if check_exist_feed_url.blank?
            article_content = ArticleContent.find_by_url(missing_url)
            status = 0
            status = 1 unless article_content.blank?

            title, description, images = Feed.get_feed_url_values(missing_url)

            # remove characters after come with space + '- or |' symbols
            title = title.to_s.gsub(/\s(-|\|).+/, '')
            title = title.blank? ? "" : title.to_s.strip

            new_feed_url = FeedUrl.create(feed_id: feed.id, url: missing_url, title: title.to_s.strip, category: category,
                                          status: status, source: source, summary: description, :images => images,
                                          :published_at => Time.now, :priorities => feed.priorities, :missing_count => missingurl_count)

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

end
