class ArticleContent < Content
  acts_as_citier


  #validates :url, :presence => true
  belongs_to :article_category
  has_many :content_photos, :foreign_key => 'content_id'
  accepts_nested_attributes_for :content_photos, :allow_destroy => true
  has_many :item_pro_cons
  #  validate :validate_end_date_before_start_date
  #
  #  def validate_end_date_before_start_date
  #    if end_date && start_date
  #      errors.add(:end_date, "should be greater than start date") if end_date < start_date
  #    end
  #  end

  MIN_SIZE =[50, 50]

  def self.CreateContent(url, user)
    @images=[]
    if url.include? "youtube.com"
      @article=VideoContent.CreateContent(url, user)
      @images << @article.thumbnail if @article.thumbnail
    else
      @article = ArticleContent.new(:url => url, :created_by => user.id)
      require 'nokogiri'
      require 'open-uri'
      begin
        begin
          doc = Nokogiri::HTML(open(url))
          @title_info = doc.xpath('.//title').to_s.strip
          @rating_value = 0
          @rating_value = doc.at("span.rating").inner_text.to_i rescue 0
          unless @rating_value == 0
            if doc.at("span")["itemprop"].to_s == 'rating'
              @rating_value = doc.at("span").inner_text.to_i rescue 0
            end
          end
          unless @rating_value == 0
            if doc.at("span")["itemprop"].to_s == 'value'
              @rating_value = doc.at("span").inner_text.to_i / 2 rescue 0
            end
          end

          doc.xpath("//meta[@name='keywords']/@content").each do |attr|
            @meta_keywords = attr.value
          end
          @meta_description = ''
          doc.xpath("//meta[@name='description']/@content").each do |attr|
            unless attr.value.nil?
              @meta_description = CGI.unescapeHTML(attr.value.to_s.gsub(/[^\x20-\x7e]/, ''))
              #@meta_description = CGI.unescapeHTML(attr.value.to_s)
            end
          end
          # doc.xpath("//link[@rel='image_src']").each do |attr|
          #   @images << CGI.unescapeHTML(attr.value)
          # end
          # doc.xpath("//link[@src]").each do |attr|
          #   @images << CGI.unescapeHTML(attr.value)
          # end
          # */

          @images = ArticleContent.get_images_from_doc(doc, @images)

        rescue OpenURI::HTTPError => e
          @title_info=""
          @meta_description =""
        end
        begin
          @article.title = CGI.unescapeHTML(@title_info.to_s.gsub(%r{</?[^>]+?>}, '')) if @title_info
        rescue
          @article.title =""
        end
        sub_type = @article.find_subtype(@article.title)
        logger.info sub_type
        @article.sub_type = sub_type
        @article.description = @meta_description if @meta_description
        @article.thumbnail = @images.first if @images.count>0
        # rescue => e
      end
    end
    [@article, @images, @rating_value]
  end

  def find_subtype(title)
    Feed.get_find_subtype(title)
  end

  def self.saveContent(val, user, ids, ip="", score="")
    if val['url'].present?
      if val['url'].include? "youtube.com"
        @article=VideoContent.saveContent(val, user, ids, ip, score)
      else
        Content.transaction do
          @article=ArticleContent.create(val)
          @article.user = user
          @article.ip_address = ip
          @article.field1 = score if score != ""
          @article.save_with_items!(ids)
        end
        @article
      end
    else
      Content.transaction do
        @article=ArticleContent.create(val)
        @article.user = user
        @article.ip_address = ip
        @article.field1 = score if score != ""
        @article.save_with_items!(ids)
      end
      @article
    end
    #rescue
    #  @article
  end

  def self.update_content(id, val, user, ids)
    if val['url'].present?
      if val['url'].include? "youtube.com"
        @article=VideoContent.update_video_content(id, val, user, ids)
      else
        ArticleContent.update_article_content(id, val, user, ids)
      end
    else
      ArticleContent.update_article_content(id, val, user, ids)
    end
  end

  def self.update_article_content(id, val, user, ids)
    @article = ArticleContent.find(id)
    #@article.update_attributes(val)
    #@article.user = user
    @article.update_with_items!(val, ids)
    @article
  end

  def update_facebook_stats
    # begin
    # puts HTTParty.get(self.facebook_statlink)
    unless (url.nil? || (url.include? ",") || (url.include? "feature=player_embedded"))
      stats = HTTParty.get(self.facebook_statlink)['links_getStats_response']
      [:url, :normalized_url, :comments_fbid, :commentsbox_count].each { |key| stats['link_stat'].delete(key.to_s) }
      facebook_count ? facebook_count.update_attributes(stats['link_stat']) : self.build_facebook_count(stats['link_stat'])
      facebook_count.save
    end
    # rescue => e
    #   return false
    # end
  end

  def facebook_statlink
    "http://api.facebook.com/restserver.php?method=links.getStats&urls=#{self.url}"
  end

  def self.get_images_from_doc(doc, images)
    doc.xpath("//meta[@property='og:image']/@content").each do |attr|
      images << CGI.unescapeHTML(attr.value)
    end
    #doc.xpath("/html/body//img[@src[contains(.,'://')
    #       and not(contains(.,'ads.') or contains(.,'ad.') or contains(.,'?'))]]//@src") .each do |attr|
    doc.xpath("/html/body//img[@src[contains(.,'://')
                   and not(contains(.,'ads.') or contains(.,'ad.'))]]//@src").each do |attr|
      images << CGI.unescapeHTML(attr.value)
    end
    images
  end

  def self.create_article_content(param, user_id, remote_ip)

    begin
      user = User.find_by_id(user_id)

      @through_rss = false

      unless param['feed_url_id'].blank?
        @through_rss = true
      end

      if param["article_content"]['sub_type'] == "Deals"
        if !param['article_content']['field3']
          param['article_content']['field3'] = "0"
        end
      end

      if param['article_content']['url']
        if param['article_content']['url'].include?("utm_source=")
          param['article_content']['url'] = param['article_content']['url'].split("?")[0]
        end
      end

      if param['article_content']['url']
        if param['article_content']['title'].include?("|")
          param['article_content']['title'] = param['article_content']['title'].slice(0..(param['article_content']['title'].index('|'))).gsub(/\|/, "").strip

        end
        if param['article_content']['title'].include?("~")
          param['article_content']['title'] = param['article_content']['title'].slice(0..(param['article_content']['title'].index('~'))).gsub(/\~/, "").strip
        end
      end

      if param['article_content']['title'] == ''
        @title = false
        return "Please Enter Title"
        #elsif param['article_content']['url']  && !ArticleContent.where(:url => param['article_content']['url']).blank?
        # @duplicate_url = 'true'
      else
        @item_id = param['item_id']
        #for bookmark
        @external = param['external']
        @item = Item.find(param['default_item_id']) unless param['default_item_id'].empty?
        #for article content create or submit
        @article_create = param['article_content_create']
        ids = param['articles_item_id'] || param['article_create_item_id']
        unless ids.blank?
          score = (param['article_content']['sub_type'] == ArticleCategory::REVIEWS) ? param['score'] : ""
          if param['article_content']['sub_type']!= "Photo"
            param["article_content"].delete("content_photos_attributes")
          end
          if (param['noincludethumbnail'] == 'on')
            param['article_content']['thumbnail'] = ''
          end
          @article=ArticleContent.saveContent(param['article_content'] || param['article_create'], user, ids, remote_ip, score)

          # Resque.enqueue(ContributorPoint, user.id, @article.id, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
          if param['submit_url'] == 'submit_url'
            ContentPhoto.save_url_content_to_local(@article)
          end

          if ((param['article_content']['sub_type'] == "Photo" || param['submit_url'] == 'submit_url') && (!@article.content_photos.first.nil?))
            @article.update_attribute('thumbnail', @article.content_photos.first.photo.url('thumb'))
          else
            Content.save_thumbnail_using_uploaded_image(@article)
          end

          if ((param['article_content']['sub_type'] == "Reviews"))
            @defaultitem = Item.find(ids[0])
            @item1 = Item.find(param['articles_item_id'])
            @item1.add_new_rating(@article) if @article.id!=nil
          end
          # unless @article.errors.any?
          #  @article.rate_it(param[:article_content][:field1],1) unless param[:article_content][:field1].nil?
          #  end
          # Point.add_point_system(user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
          UserActivity.save_user_activity(user, @article.id, "created", @article.sub_type, @article.id, remote_ip) if @article.id!=nil
          content_id = @article.id
          if user.total_points < 10
            @article.update_attribute('status', Content::SENT_APPROVAL)
            @display = 'false'
          elsif @article.url!=nil
            Point.add_point_system(user, @article, Point::PointReason::CONTENT_SHARE) unless @article.errors.any?
          else
            Point.add_point_system(user, @article, Point::PointReason::CONTENT_CREATE) unless @article.errors.any?
          end
          @facebook_post = param['facebook_post']
          Follow.content_follow(@article, user) if @article.id!=nil
          # @article,@images = ArticleContent.CreateContent(@article.url,user) unless @article.url.blank?
          if param['article_content']['url'] && @article.id!=nil
            url = param['article_content']['url']
            url = "http://#{url}" if URI.parse(url).scheme.nil?
            host = URI.parse(url).host.downcase
            updated_host = host.start_with?('www.') ? host[4..-1] : host
            @article.update_attributes!(:domain => updated_host)
          end

          if (@article.id != nil && !param['feed_url_id'].blank?)
            feed_url = FeedUrl.where("id = ?", param['feed_url_id']).first
            feed_url.update_attributes(:status => 1)
          end
        else
          @tag = 'false'
          return "Please at least one product"
        end
      end

      unless (@article.nil?)
        @article.update_facebook_stats
      end

      return "success"

    rescue Exception => e
      feed_url = FeedUrl.where("id = ?", param['feed_url_id']).first
      feed_url.update_attributes(:status => 3)
      return e
    end
  end

end
