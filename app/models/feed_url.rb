class FeedUrl < ActiveRecord::Base
  belongs_to :feed

  def self.update_by_missing_records(log)
    missing_keys = get_missing_keys_from_redis

    # separate missingurl and missingad
    missingurl_keys = []
    missingad_keys = []
    missing_keys.each do |each_key|
      if each_key.include?("missingurl:")
        missingurl_keys << each_key
      elsif each_key.include?("missingad")
        missingad_keys << each_key
      end
    end

    # process for missingurl
    process_missing_url(missingurl_keys)

    # Process missingad
    process_missing_ad(missingad_keys)
  end

  def self.process_missing_url(missingurl_keys=[])
    missingurl_keys.each do |each_url_key|
      missingurl_count = $redis_rtb.hget(each_url_key, 'count')
      if missingurl_count.to_i > 10
        missing_url = each_url_key.split("missingurl:")[1]

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

        check_exist_feed_url = FeedUrl.where(:url => missing_url).first
        if check_exist_feed_url.blank?
          article_content = ArticleContent.find_by_url(missing_url)
          status = 0
          status = 1 unless article_content.blank?

          title, description, images = Feed.get_feed_url_values(missing_url)

          # remove characters after come with space + '- or |' symbols
          title = title.to_s.gsub(/\s(-|\|).+/, '')
          title = title.blank? ? "" : title.to_s.strip

          feed = Feed.where("process_type = 'missingurl'").last

          FeedUrl.create(feed_id: feed.id, url: missing_url, title: title.to_s.strip, category: category,
                           status: status, source: source, summary: description, :images => images,
                           :published_at => Time.now, :priorities => feed.priorities, :missing_count => missingurl_count)
        else
          new_count = check_exist_feed_url.missing_count + missingurl_count.to_i
          check_exist_feed_url.update_attributes(:missing_count => new_count)
        end

        # remove key from redis
        $redis_rtb.del(each_url_key) if Rails.env == "production"
      end
    end
  end

  def self.process_missing_ad(missingad_keys)
    missingad_keys.each do |each_ad_key|
      missingad_count = $redis_rtb.hget(each_ad_key, 'count')
      missing_ad_url = each_ad_key.split("missingad:")[1]

      missing_ad_detail = MissingAdDetail.find_or_initialize_by_url(:url => missing_ad_url)

      missingad_count = missing_ad_detail.count.to_i + missingad_count.to_i unless missing_ad_detail.new_record?
      missing_ad_detail.update_attributes(:count => missingad_count.to_i)

      $redis_rtb.hset(each_ad_key, 'count', 0) if Rails.env == "production"
    end
  end

  def self.get_missing_keys_from_redis
    exp_val = []
    next_val = 0
    begin
      redis_val = $redis_rtb.scan(next_val, match: 'missing*', count: 300)
      next_val = redis_val[0].to_i
      val = redis_val[1]
      exp_val << val
    end while next_val != 0

    exp_val.flatten
  end

end
