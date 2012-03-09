class ArticleContent < Content
  acts_as_citier
  validates_presence_of :url
  belongs_to :article_category
  
  MIN_SIZE =[25,25]
  
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
        @title_info = doc.xpath('.//title')
        doc.xpath("//meta[@name='keywords']/@content").each do |attr|
          @meta_keywords = attr.value
        end
        doc.xpath("//meta[@name='description']/@content").each do |attr|
          @meta_description = attr.value
        end
        doc.xpath("//link[@rel='image_src']/@href").each do |attr|
          @images << attr.value
        end
        doc.xpath("//meta[@property='og:image']/@content").each do |attr|
          @images << attr.value
        end
        doc.xpath("/html/body//img[@src[contains(.,'://') 
               and not(contains(.,'ads.') or contains(.,'ad.') or contains(.,'?'))]]//@src") .each do |attr|
          @images << attr.value
        end
        
        @article.title = @title_info.to_s.gsub(%r{</?[^>]+?>}, '') if @title_info
        @article.description = @meta_description if @meta_description
        @article.thumbnail = @images.first   if @images.count>0
      rescue => e
      end
    end
    @sizes=[]
    @fimages=[]
    if @images.count>0
      @images.uniq.each do |image|
        size = FastImage.size(image)
        if(size[0] >= MIN_SIZE[0] && size[1] >= MIN_SIZE[1])
          @fimages << image
          @sizes << size
        end
      end
    end
    [@article,@fimages,@sizes]
  end
  
  def self.saveContent(val, user, ids)
    if val['url'].include? "youtube.com"
      @article=VideoContent.saveContent(val, user, ids)
    else
      @article=ArticleContent.create(val)
      @article.user = user
      @article.save_with_items!(ids) 
      @article
    end
  end
  
end
