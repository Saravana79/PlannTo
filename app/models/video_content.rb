class VideoContent < ArticleContent
  # acts_as_citier
  acts_as_voteable
  
  def self.video_id(url)
    uri = URI.parse(url)
    cgiuri = CGI.parse(uri.query)
    if cgiuri["v"]
      cgiuri["v"].first
    else
      uri.path
    end
  end
  
  def self.CreateContent(url, user)
    @article = VideoContent.create(:url => url, :created_by => user.id)
    client = YouTubeIt::Client.new
    require 'youtube_it'  
    video_id=self.video_id(url)
    @article.field4 = video_id
    #    @article.youtube = video_id
    
    youtube_data = client.video_by(video_id)
    @article.title = youtube_data.title if youtube_data.title
    @article.description = youtube_data.description if youtube_data.description
    @article.thumbnail = youtube_data.thumbnails.first.url if youtube_data.thumbnails.first.url
    @article
  end
  
  def self.saveContent(val,user,ids, ip="", score="")
    @article = VideoContent.create(val)
    @article.field1 =  score if score != ""
    @article.video = true
    url = @article.url
    if url.split('v=')[1]
      video_id = (url.split('v=')[1]).split('&')[0]
    elsif url.split('/v/')
      video_id = (url.split('v=')[1]).split('&')[0]
    end
    
    @article.field4 = video_id
    @article.ip_address = ip
    @article.type = "ArticleContent"
    @article.user=user
    @article.save_with_items!(ids) 
    @article
  end

  def self.update_video_content(id, val, user, ids)
    @article = ArticleContent.find(id)

    @article.update_attributes(val)
    @article.video = true
    url = @article.url
    if url.split('v=')[1]
      video_id = (url.split('v=')[1]).split('&')[0]
    elsif url.split('/v/')
      video_id = (url.split('v=')[1]).split('&')[0]
    end
    @article.field4 = video_id
    @article.user=user
    @article.update_with_items!(val, ids)

    @article
  end
end
