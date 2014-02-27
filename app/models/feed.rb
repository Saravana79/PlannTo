class Feed < ActiveRecord::Base
  validates :category, :url, :presence => true
  has_many :feed_urls

  def self.process_feeds
    @feeds = Feed.all
    @feeds.each do |each_feed|
      feed = Feedzirra::Feed.fetch_and_parse(each_feed.url)
      if (!feed.blank? && feed != 0)
        latest_feeds = feed.entries.select {|each_val| each_val.published > (each_feed.last_updated_at.blank? ? Time.now-2.day : each_feed.last_updated_at)}

        latest_feeds.each do |each_entry|
          feed_url = FeedUrl.where("url = ?", each_entry.url)
          source = URI.parse(URI.encode(URI.decode(each_entry.url))).host.gsub("www.","")
          if (feed_url.count == 0)
            FeedUrl.create(feed_id: each_feed.id, url: each_entry.url, title: each_entry.title, category: each_feed.category, status: 0, source: source, summary: each_entry.summary)
          end
        end
        each_feed.update_attributes!(last_updated_at: feed.last_modified)
      end
    end
  end

end
