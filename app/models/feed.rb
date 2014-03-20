class Feed < ActiveRecord::Base
  validates :category, :presence => true
  validates :url, :presence => true, :if => Proc.new{|f| f.process_type != "table"}
  has_many :feed_urls

  def self.process_feeds
    puts "************************************************* Process Started at - #{Time.now.strftime('%b %d,%Y %r')} *************************************************"
    @feeds = Feed.all
    feed_url_count = FeedUrl.count
    begin
      @feeds.each do |each_feed|
        if each_feed.process_type == "feed"
          each_feed.feed_process()
        elsif each_feed.process_type == "table"
          each_feed.table_process()
        end
      end
    rescue Exception => e
      puts e
    end
    created_feed_urls = FeedUrl.count - feed_url_count
    puts "************************************* Process Completed at - #{Time.now.strftime('%b %d,%Y %r')} - #{created_feed_urls} feed_urls created *************************************"
    created_feed_urls
  end

  def feed_process()
    feed = Feedzirra::Feed.fetch_and_parse(self.url)
    if (!feed.blank? && feed != 0)
      latest_feeds = feed.entries

      if !self.last_updated_at.blank?
        latest_feeds = latest_feeds.select {|each_val| each_val.published > self.last_updated_at}
      end

      latest_feeds.each do |each_entry|
        feed_url = FeedUrl.where("url = ?", each_entry.url)
        source = URI.parse(URI.encode(URI.decode(each_entry.url))).host.gsub("www.","")
        if (feed_url.count == 0)
          article_content = ArticleContent.find_by_url(each_entry.url)
          status = 0
          status = 1 unless article_content.blank?
          check_exist_feed_url = FeedUrl.where(:url => each_entry.url, :category => category).first

          if check_exist_feed_url.blank?
            FeedUrl.create(feed_id: self.id, url: each_entry.url, title: each_entry.title, category: self.category,
                           status: status, source: source, summary: each_entry.summary, :published_at => each_entry.published)
          end
        end
      end
      self.update_attributes!(last_updated_at: feed.last_modified)
    end
  end

  def table_process()
    @impression_missing = ImpressionMissing.where("updated_at > ? and count > ?", (self.last_updated_at.blank? ? Time.now-2.days : self.last_updated_at), 10)

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
        source = URI.parse(URI.encode(URI.decode(each_record.hosted_site_url))).host.gsub("www.", "")
      end

      category = "Others"

      if source != ""
        feed_by_source = FeedUrl.find_by_source(source)
        category = feed_by_source.blank? ? 'Others' : feed_by_source.category
      end

      check_exist_feed_url = FeedUrl.where(:url => each_record.hosted_site_url, :category => category).first

      if check_exist_feed_url.blank?
        @feed_url = FeedUrl.create(:url => each_record.hosted_site_url, :status => status, :source => source, :category => category,
                                 :feed_id => self.id, :published_at => each_record.created_at)
      end
    end
    self.update_attributes(:last_updated_at => Time.now)
  end

end
