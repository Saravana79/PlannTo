namespace :feed do
  desc 'update feed_url with ImpressionMissing table'
  task :process_table_feeds => :environment do
    @feed = Feed.find_by_process_value("ImpressionMissing")
    unless @feed.blank?
      logger.info "Please create a feed with ImpressionMissing as process_value and table as process type"
      return
    end
    @impression_missing = ImpressionMissing.all

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
                                 :feed_id => @feed.id)
    end
  end
end