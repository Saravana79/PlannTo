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
          doc = Nokogiri::HTML(open(url, "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"))
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
        sub_type = "Others" if sub_type.blank?
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
            url = "http://#{url}" if Addressable::URI.parse(url).scheme.nil?
            host = Addressable::URI.parse(url).host.downcase
            updated_host = host.start_with?('www.') ? host[4..-1] : host
            @article.update_attributes!(:domain => updated_host)
          end

          if (@article.id != nil && !param['feed_url_id'].blank?)
            feed_url = FeedUrl.where("id = ?", param['feed_url_id']).first
            feed_url.update_attributes(:status => 1, :article_content_id => @article.id)
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
      feed_url.update_attributes(:status => 0)
      return e
    end
  end

  def self.get_best_deals(item_ids, url, url_params, is_test, user, remote_ip, plan_to_temp_user_id)
    @item = Item.find(item_ids[0])
    root_id = Item.get_root_level_id(@item.itemtype.itemtype)
    temp_item_ids = item_ids + root_id.to_s.split(",")
    @best_deals = ArticleContent.select("distinct view_article_contents.*").joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in (?) and view_article_contents.sub_type=? and view_article_contents.status=? and view_article_contents.field3=? and (view_article_contents.field1=? or str_to_date(view_article_contents.field1,'%d/%m/%Y') > ? )", temp_item_ids, 'deals', 1, '0', '', Date.today.strftime('%Y-%m-%d')).order("field4 asc, id desc")
    unless @best_deals.blank?
      itemsaccess ="offeritem_ids"
      # @impression_id = AddImpression.save_add_impression_data("OffersDeals",item_ids[0],url,Time.zone.now,user,request.remote_ip,nil,itemsaccess,url_params, cookies[:plan_to_temp_user_id], nil)

      # @impression_id = SecureRandom.uuid
      # impression_params = {:imp_id => @impression_id, :type => "OffersDeals", :itemid => item_ids[0], :request_referer => url, :time => Time.zone.now, :user => user.blank? ? nil : user.id, :remote_ip => remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
      #                      :params => url_params, :temp_user_id => plan_to_temp_user_id, :ad_id => nil}.to_json

      @impression_id = nil
      impression_params = {:imp_id => @impression_id, :type => "OffersDeals", :itemid => item_ids[0], :request_referer => url, :time => Time.zone.now, :user => user.blank? ? nil : user, :remote_ip => remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
                           :params => url_params, :temp_user_id => plan_to_temp_user_id, :ad_id => nil}
      @impression_id = AddImpression.add_impression_to_resque(impression_params[:type], impression_params[:item_id], impression_params[:request_referer], impression_params[:user], impression_params[:remote_ip], impression_params[:impression_id], impression_params[:itemaccess], impression_params[:params], impression_params[:temp_user_id], impression_params[:ad_id], nil) if @is_test != "true"

      # Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params) if is_test != "true"

      @best_deals.select { |a| a }
    else
      @impression = ImpressionMissing.find_or_create_by_hosted_site_url_and_req_type(url, "OffersDeals")
      if @impression.new_record?
        @impression.update_attributes(created_time: Time.zone.now, updated_time: Time.zone.now)
      else
        @impression.update_attributes(updated_time: Time.zone.now, :count => @impression.count + 1)
      end
    end
    return @item, @best_deals, @impression_id
  end

  def check_and_update_mobile_site_feed_urls_from_content(feed_url, user, remote_ip)
    new_feed_url = nil
    url = feed_url.blank? ? self.url : feed_url.url
    old_host = Addressable::URI.parse(url).host.downcase
    host = old_host.start_with?('www.') ? old_host[4..-1] : old_host
    source_category = SourceCategory.where(:source => host).last
    if !source_category.blank? && !source_category.prefix.blank?
      prefix = source_category.prefix
      processed_host = host.include?(prefix) ? host.gsub(prefix, '') : prefix+host
      processed_url = url.gsub(old_host, "%#{processed_host}%")

      # new_feed_url = FeedUrl.where(:url => processed_url, :status => 0).last
      new_feed_url = FeedUrl.where("url like ? and status = 0", processed_url).last

      unless new_feed_url.blank?
        param = {}
        item_ids = ContentItemRelation.where(:content_id => self.id).map(&:item_id)
        article_item_ids = item_ids.join(",")

        param.merge!(:feed_url_id => new_feed_url.id, :default_item_id => "", :submit_url => "submit_url",
                     :article_content => { :itemtype_id => self.itemtype_id, :type => self.type, :thumbnail => self.thumbnail,
                                           :title => self.title, :url => url, :sub_type => self.sub_type, :description => self.description },
                     :share_from_home => "", :detail => "", :articles_item_id => article_item_ids, :external => "true", :score => "0")

        param.merge!(:score => self.field1) if self.sub_type == ArticleCategory::REVIEWS
        Resque.enqueue(ArticleContentProcess, "create_article_content", Time.zone.now, param.to_json, user.blank? ? nil : user.id, remote_ip)
        new_feed_url.update_attributes!(:status => 1, :default_status => 6)
      end
    end
    new_feed_url
  end

  def self.check_and_update_mobile_site_feed_urls_from_feed(feed_url, user, remote_ip, param_url='')
    url = feed_url.blank? ? param_url : feed_url.url
    article_content = nil
    old_host = Addressable::URI.parse(url).host.downcase
    host = old_host.start_with?('www.') ? old_host[4..-1] : old_host
    source_category = SourceCategory.where(:source => host).last
    if !source_category.blank?
      if !source_category.prefix.blank?
        prefix = source_category.prefix
        splitted_prefix = prefix.to_s.split("~").map {|each_val| each_val.split("^")}.flatten.map(&:strip)
        if (splitted_prefix.count % 2 == 0)
          hash_details = Hash[*splitted_prefix]
          hash_details.each do |key, val|
            if url.include?(key)
              processed_url = url.gsub(key, "%")
              article_content = @article_content = ArticleContent.where("url like ?", processed_url).last
              unless article_content.blank?
                article_content.sub_type = val
                break
              end
            end
          end
          feed_url = ArticleContent.create_article_params_and_put_in_resque(article_content, url, user, remote_ip, feed_url) unless article_content.blank?
        else
          prefix = splitted_prefix.first
          processed_host = host.include?(prefix) ? host.gsub(prefix, '') : prefix+host
          processed_url = url.gsub(old_host, "%#{processed_host}%")

          article_content = @article_content = ArticleContent.where("url like ?", processed_url).last
          # new_feed_url = FeedUrl.where(:url => processed_url, :status => 0)
          feed_url = ArticleContent.create_article_params_and_put_in_resque(article_content, url, user, remote_ip, feed_url) unless article_content.blank?
        end
      end

      if !source_category.pattern.blank?
        pattern = source_category.pattern
        str1, str2 = pattern.split("<page>")
        exp_val = url[/.*#{Regexp.escape(str1.to_s)}(.*?)#{Regexp.escape(str2.to_s)}/m, 1]
        if exp_val.to_s.is_an_integer?
          patten_with_val = pattern.gsub("<page>", exp_val)
          patten_for_query = pattern.gsub("<page>", "%")
          url_for_query = url.gsub(patten_with_val, patten_for_query)
          article_content = @article_content = ArticleContent.where("url like ?", url_for_query).last
          feed_url = ArticleContent.create_article_params_and_put_in_resque(article_content, url, user, remote_ip, feed_url) unless article_content.blank?
        end
      end
    end
    return feed_url.reload, article_content
  end

  def self.create_article_params_and_put_in_resque(article_content, url, user, remote_ip, feed_url=nil)
    param = {}
    item_ids = ContentItemRelation.where(:content_id => article_content.id).map(&:item_id)
    article_item_ids = item_ids.join(",")

    param.merge!(:feed_url_id => feed_url.blank? ? nil : feed_url.id, :default_item_id => "", :submit_url => "submit_url",
                 :article_content => { :itemtype_id => article_content.itemtype_id, :type => article_content.type, :thumbnail => article_content.thumbnail,
                                       :title => article_content.title, :url => url, :sub_type => article_content.sub_type, :description => article_content.description },
                 :share_from_home => "", :detail => "", :articles_item_id => article_item_ids, :external => "true", :score => "0")

    param.merge!(:score => article_content.field1) if article_content.sub_type == ArticleCategory::REVIEWS
    Resque.enqueue(ArticleContentProcess, "create_article_content", Time.zone.now, param.to_json, user.blank? ? nil : user.id, remote_ip)
    feed_url.update_attributes!(:status => 1, :default_status => 6) if !feed_url.blank?
    feed_url
  end

end