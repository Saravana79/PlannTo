class ArticleContent < Content
  acts_as_citier

  validates :url, :uniqueness => true, :if => Proc.new {  |c|  !c.url.blank? }
  #validates :url, :presence => true
  belongs_to :article_category
  has_one :content_photo,  :foreign_key => 'content_id'

 
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
        
        doc = Nokogiri::HTML(open(url))
        @title_info = doc.xpath('.//title').to_s.strip
        doc.xpath("//meta[@name='keywords']/@content").each do |attr|
          @meta_keywords = attr.value
        end
        @meta_description = ''
        doc.xpath("//meta[@name='description']/@content").each do |attr|
          @meta_description = attr.value.strip
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
        
        @article.title = CGI.unescapeHTML(@title_info.to_s.gsub(%r{</?[^>]+?>}, '')) if @title_info
        @article.description = @meta_description if @meta_description
        @article.thumbnail = @images.first   if @images.count>0
     # rescue => e
      end
    end
    [@article,@images]
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
