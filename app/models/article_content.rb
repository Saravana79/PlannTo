class ArticleContent < Content
  acts_as_citier
  validates_uniqueness_of :url
  
  def self.CreateContent(url, user)
    if url.include? "youtube.com"
      @article=VideoContent.CreateContent(url, user)
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
          @meta_image = attr.value
        end
        @article.title = @title_info.to_s.gsub(%r{</?[^>]+?>}, '') if @title_info
        @article.description = @meta_description if @meta_description
        @article.thumbnail = @meta_image   if @meta_image
      rescue => e
      end
    end
    @article
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
