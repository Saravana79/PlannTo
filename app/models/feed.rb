class Feed < ActiveRecord::Base
  validates :category, :presence => true
  validates :url, :presence => true, :if => Proc.new{|f| f.process_type != "table"}
  has_many :feed_urls

  def self.process_feeds
    @feeds = Feed.all
    @feeds.each do |each_feed|
      if each_feed.process_type == "feed"
        each_feed.feed_process()
      elsif each_feed.process_type == "table"
        each_feed.table_process()
      end
    end
  end

  def feed_process()
    feed = Feedzirra::Feed.fetch_and_parse(each_feed.url)
    if (!feed.blank? && feed != 0)
      latest_feeds = feed.entries.select {|each_val| each_val.published > (each_feed.last_updated_at.blank? ? Time.now-2.day : each_feed.last_updated_at)}

      latest_feeds.each do |each_entry|
        feed_url = FeedUrl.where("url = ?", each_entry.url)
        source = URI.parse(URI.encode(URI.decode(each_entry.url))).host.gsub("www.","")
        if (feed_url.count == 0)
          article_content = ArticleContent.find_by_url(each_entry.url)
          status = 0
          status = 1 unless article_content.blank?
          FeedUrl.create(feed_id: each_feed.id, url: each_entry.url, title: each_entry.title, category: each_feed.category, status: status, source: source, summary: each_entry.summary)
        end
      end
      each_feed.update_attributes!(last_updated_at: feed.last_modified)
    end
  end

  def table_process()
    @impression_missing = ImpressionMissing.where("updated_at > ?", (self.last_updated_at.blank? ? Time.now-2.days : self.last_updated_at))

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

      @feed_url = FeedUrl.create(:url => each_record.hosted_site_url, :status => status, :source => source, :category => "Others",
                                 :feed_id => self.id)
    end
  end

end
