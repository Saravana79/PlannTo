namespace :feed do
  desc 'update feed_url with ImpressionMissing table'
  task :process_table_feeds => :environment do
    @feed = Feed.find_by_process_value("ImpressionMissing")
    if @feed.blank?
      puts "**************************************************************************************"
      puts "Please create a feed with ImpressionMissing as process_value and table as process type"
      puts 'attributes => {"title"=>"Process via impression_missing table", "category"=>"Others", "process_type"=>"table", "process_value"=>"ImpressionMissing"}'
      puts "**************************************************************************************"
      next
    end

    @impression_missing = @feed.process_value.constantize.where("count > ?", 100)

    count = 0
    @impression_missing.each do |each_record|
      count = count + 1
      status = 0
      status_val = {"1" => 1, "3" => 2, "4" => 3}
      status_val.default = 0

      status = status_val[each_record.status.to_s] unless each_record.status.blank?

      article_content = ArticleContent.find_by_url(each_record.hosted_site_url)
      status = 1 unless article_content.blank?

      source = ""
      if (each_record.hosted_site_url =~ URI::regexp).blank?
        source = ""
        status = 3
      else
        source = URI.parse(URI.encode(URI.decode(each_record.hosted_site_url))).host.gsub("www.", "")
      end

      # sources_list = Rails.cache.read("sources_list_details")
      sources_list = JSON.parse($redis_rtb.get("sources_list_details"))
      sources_list.default = "Others"
      category = sources_list[source]

      check_exist_feed_url = FeedUrl.where(:url => each_record.hosted_site_url).first

      if check_exist_feed_url.blank?

        title, description, images = Feed.get_feed_url_values(each_record.hosted_site_url)

        url_for_save = each_record.hosted_site_url
        if url_for_save.include?("youtube.com")
          url_for_save = url_for_save.gsub("watch?v=", "video/")
        end

        # remove characters after come with space + '- or |' symbols
        title = title.to_s.gsub(/\s(-|\|).+/, '')
        title = title.blank? ? "" : title.strip

        @feed_url = FeedUrl.new(:url => url_for_save, :title => title.strip, :status => status, :source => source,
                                   :category => category, :summary => description, :images => images,
                                   :feed_id => @feed.id, :published_at => each_record.created_at, :priorities => @feed.priorities)

        begin
          @feed_url.save!
        rescue Exception => e
          p e
        end

      end
    end
    @feed.update_attributes(:last_updated_at => Time.zone.now)

    puts "**************************************************************************************"
    puts "Successfully created #{count} feed_urls from #{@feed.process_value} table"
    puts "**************************************************************************************"
  end

  desc 'update feed_url title, summary and images based on nokogiri'
  task :update_feed_url_values => :environment do
    puts "**************************************************************************************"
    puts "Started to update feed_url values"
    puts "**************************************************************************************"

    @feed_urls = FeedUrl.all
    count = 0
    @feed_urls.each do |each_feed_url|
      count = count + 1
      begin
        title, description, images = Feed.get_feed_url_values(each_feed_url.url)

        url_for_save = each_feed_url.url
        if url_for_save.include?("youtube.com")
          url_for_save = url_for_save.gsub("watch?v=", "video/")
        end

        each_feed_url.update_attributes(:title => title.strip, :summary => description, :images => images, :url => url_for_save)
        puts "Updated #{count} of #{@feed_urls.count} feed_urls remaining #{@feed_urls.count - count} values \n"
      rescue Exception => e
        puts "Error while process FeedUrl"
        puts e
      end
    end

    puts "**************************************************************************************"
    puts "Successfully updated #{count} feed_urls"
    puts "**************************************************************************************"
  end
end