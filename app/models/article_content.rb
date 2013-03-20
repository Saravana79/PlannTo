class ArticleContent < Content
  acts_as_citier

  
  #validates :url, :presence => true
  belongs_to :article_category
  has_many :content_photos,  :foreign_key => 'content_id'
  accepts_nested_attributes_for :content_photos, :allow_destroy => true
  #  validate :validate_end_date_before_start_date
  #
  #  def validate_end_date_before_start_date
  #    if end_date && start_date
  #      errors.add(:end_date, "should be greater than start date") if end_date < start_date
  #    end
  #  end

  MIN_SIZE =[50,50]

  def self.CreateContent(url, user)
    @images=[]
    if url.include? "youtube.com"
      @article=VideoContent.CreateContent(url, user)
    @images << @article.thumbnail if @article.thumbnail
    else
      @article = ArticleContent.create(:url => url, :created_by => user.id)
      require 'nokogiri'
      require 'open-uri'
      begin
        begin
            doc = Nokogiri::HTML(open(url))
            @title_info = doc.xpath('.//title').to_s.strip
            doc.xpath("//meta[@name='keywords']/@content").each do |attr|
              @meta_keywords = attr.value
            end
            @meta_description = ''
            doc.xpath("//meta[@name='description']/@content").each do |attr|
              unless attr.value.nil?
                @meta_description = CGI.unescapeHTML(attr.value.to_s.gsub(/[^\x20-\x7e]/,''))
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
            doc.xpath("//meta[@property='og:image']/@content").each do |attr|
              @images << CGI.unescapeHTML(attr.value)
            end
            #doc.xpath("/html/body//img[@src[contains(.,'://')
            #       and not(contains(.,'ads.') or contains(.,'ad.') or contains(.,'?'))]]//@src") .each do |attr|
            doc.xpath("/html/body//img[@src[contains(.,'://')
                   and not(contains(.,'ads.') or contains(.,'ad.'))]]//@src") .each do |attr|
              @images << CGI.unescapeHTML(attr.value)
            end
        rescue OpenURI::HTTPError=>e
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
      @article.thumbnail = @images.first   if @images.count>0
      # rescue => e
      end
    end
    [@article,@images]
  end

  def find_subtype(title)  
    title_words = title.downcase #.split
    
    tips = %w[tip trick]
    reviews = %w[review vs]
    how_to = ["tutorial", "guide", "how to"]
    how_to.each do |how|
      return ArticleCategory::HOW_TO if title_words.scan(how).size > 0
    end
    logger.info "how to"
    tips.each do |tip|
      
      return ArticleCategory::TIPS if title_words.scan(tip).size >0
    end
    reviews.each do |review|
      return ArticleCategory::REVIEWS if title_words.scan(review).size >0
    end

    return ""

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
  rescue
    @article
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

end
