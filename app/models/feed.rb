class Feed < ActiveRecord::Base
  validates :category, :presence => true
  validates :url, :presence => true, :if => Proc.new { |f| f.process_type != "table" }
  has_many :feed_urls
  after_create :start_process_feeds

  def self.process_feeds(feed_ids=[])
    puts "************************************************* Process Started at - #{Time.zone.now.strftime('%b %d,%Y %r')} *************************************************"

    if feed_ids.blank?
      @feeds = Feed.all
    else
      @feeds = Feed.where("id in (?)", feed_ids)
    end

    feed_url_count = FeedUrl.count

    @feeds.each do |each_feed|
      begin
        if each_feed.process_type == "feed"
          each_feed.feed_process()
        elsif each_feed.process_type == "table"
          each_feed.table_process()
        end
      rescue Exception => e
        puts e.backtrace
      end
    end

    created_feed_urls = FeedUrl.count - feed_url_count
    puts "************************************* Process Completed at - #{Time.zone.now.strftime('%b %d,%Y %r')} - #{created_feed_urls} feed_urls created *************************************"
    created_feed_urls
  end

  def feed_process()
    feed = Feedzirra::Feed.fetch_and_parse(url)
    admin_user = User.where(:is_admin => true).first

    if (!feed.blank? && feed != 0)
      latest_feeds = feed.entries

      if !self.last_updated_at.blank?
        latest_feeds = latest_feeds.select { |each_val| each_val.published > self.last_updated_at }
      end

      latest_feeds = latest_feeds.last(200)

      latest_feeds.each do |each_entry|
        check_exist_feed_url = FeedUrl.where(:url => each_entry.url).first
        if check_exist_feed_url.blank?
          begin
            source = URI.parse(URI.encode(URI.decode(each_entry.url))).host.gsub("www.", "")
          rescue Exception => e
            source = Addressable::URI.parse(each_entry.url).host.gsub("www.", "")
          end
          article_content = ArticleContent.find_by_url(each_entry.url)
          status = 0
          status = 1 unless article_content.blank?

          title, description, images = Feed.get_feed_url_values(each_entry.url)

          # remove characters after come with space + '- or |' symbols
          title = title.to_s.gsub(/\s(-|\|).+/, '')
          title = title.blank? ? "" : title.to_s.strip

          new_feed_url = FeedUrl.new(feed_id: id, url: each_entry.url, title: title.to_s.strip, category: category,
                         status: status, source: source, summary: description, :images => images,
                         :published_at => each_entry.published, :priorities => priorities)

          begin
            new_feed_url.save!
            feed_url, article_content = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(new_feed_url, admin_user, nil)
          rescue Exception => e
            p e
          end
        end
      end
      self.update_attributes!(last_updated_at: feed.last_modified)
    end
  end

  def table_process()
    @impression_missing = ImpressionMissing.where("updated_at > ? and count > ?", (self.last_updated_at.blank? ? Time.zone.now-2.days : self.last_updated_at), 50)
    admin_user = User.where(:is_admin => true).first

    @impression_missing.each do |each_record|
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
        begin
          source = URI.parse(URI.encode(URI.decode(each_record.hosted_site_url))).host.gsub("www.", "")
        rescue Exception => e
          source = Addressable::URI.parse(each_record.hosted_site_url).host.gsub("www.", "")
        end
      end

      # sources_list = Rails.cache.read("feed_url-sources-list")
      sources_list = JSON.parse($redis_rtb.get("feed_url-sources-list"))
      sources_list.default = "Others"
      category = sources_list[source]

      check_exist_feed_url = FeedUrl.where(:url => each_record.hosted_site_url).first

      if check_exist_feed_url.blank?

        title, description, images = Feed.get_feed_url_values(each_record.hosted_site_url)

        # remove characters after come with space + '- or |' symbols
        title = title.to_s.gsub(/\s(-|\|).+/, '')
        title = title.blank? ? "" : title.to_s.strip

        @feed_url = FeedUrl.new(:url => each_record.hosted_site_url, :title => title.to_s.strip, :status => status, :source => source,
                                   :category => category, :summary => description, :images => images,
                                   :feed_id => self.id, :published_at => each_record.created_at, :priorities => self.priorities, :missing_count => each_record.count)

        begin
          @feed_url.save!
          feed_url, article_content = ArticleContent.check_and_update_mobile_site_feed_urls_from_feed(@feed_url, admin_user, nil)
        rescue Exception => e
          p e
        end
        
      else
        new_count = each_record.count
        check_exist_feed_url.update_attributes(:missing_count => new_count)
      end
    end
    self.update_attributes(:last_updated_at => Time.zone.now)
  end

  def self.get_find_subtype(title)
    title_words = title.to_s.downcase #.split

    tips = ['tip ', 'trick ']
    reviews = [' review', 'first impression', 'hands on', 'hands-on', 'first look', 'unboxing','handson']
    comparisons = [' vs ','versus','comparison','competitor']
    how_to = ["tutorial", "guide", "how to",'update','Wallpaper',' root',' reset']
    lists = ["top ", "best "]
    photos = ["gallery",'photos','picture']
    news = ['launch', 'release', 'online', 'available', 'announce', 'official','upcoming','unveiled','leaks', ' Rs']
    specs = [' spec',' 3D']
    how_to.each do |how|
      return ArticleCategory::HOW_TO if title_words.scan(how).size > 0
    end
    # logger.info "how to"
    tips.each do |tip|
      return ArticleCategory::HOW_TO if title_words.scan(tip).size >0
    end

    
    reviews.each do |review|
      return ArticleCategory::REVIEWS if title_words.scan(review).size >0
    end
    
    comparisons.each do |comparison|
      return ArticleCategory::COMPARISONS if title_words.scan(comparison).size >0
    end

    specs.each do |spec|
      return ArticleCategory::SPECS if title_words.scan(spec).size >0
    end

    lists.each do |list|
      return ArticleCategory::LIST if title_words.scan(list).size >0
    end

 
    photos.each do |images|
      return ArticleCategory::PHOTO if title_words.scan(images).size >0
    end
  
    news.each do |each_news|
      return ArticleCategory::NEWS if title_words.scan(each_news).size >0
    end

    return ""
  end

  private

  def self.get_feed_url_values(url)
    begin
      uri = URI.parse(URI.encode(url.to_s.strip))
      doc = Nokogiri::HTML(open(uri, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0", :allow_redirections => :all))
      title_info = doc.xpath('.//title').to_s.strip
      rating_value = 0
      meta_description = ''
      images = []

      rating_value = doc.at("span.rating").inner_text.to_i rescue 0
      unless rating_value == 0
        if doc.at("span")["itemprop"].to_s == 'rating'
          rating_value = doc.at("span").inner_text.to_i rescue 0
        end
      end
      unless rating_value == 0
        if doc.at("span")["itemprop"].to_s == 'value'
          rating_value = doc.at("span").inner_text.to_i / 2 rescue 0
        end
      end

      doc.xpath("//meta[@name='description']/@content").each do |attr|
        unless attr.value.nil?
          meta_description = CGI.unescapeHTML(attr.value.to_s.gsub(/[^\x20-\x7e]/, ''))
        end
      end

      # category

      page_category = ""
      watch_meta_item = doc.search('.watch-meta-item')
      watch_meta_item.each {|each_item| page_category = each_item.search('.content li a.spf-link').inner_text.to_s.strip if each_item.search('.title').inner_text.to_s.strip == "Category"}
      # page_category = doc.css(".content #eow-category").inner_text.to_s.strip rescue ""

      images = ArticleContent.get_images_from_doc(doc, images)
      images = [] if images.blank?

    rescue => e
      title_info = ""
      meta_description = ""
    end
    begin
      title_info = CGI.unescapeHTML(title_info.to_s.gsub(%r{</?[^>]+?>}, '')) if title_info
    rescue
      title_info = ""
    end

    images = images.join(',') rescue ""

    return title_info, meta_description, images, page_category
  end

  private

  def start_process_feeds
    Resque.enqueue(FeedProcess, "process_feeds", Time.zone.now, self.id, false)
  end


end
