class VideoContent < ArticleContent
  acts_as_citier
  acts_as_voteable
  @@video_regexp = [ /^(?:https?:\/\/)?(?:www\.)?youtube\.com(?:\/v\/|\/watch\?v=)([A-Za-z0-9_-]{11})/, 
                     /^(?:https?:\/\/)?(?:www\.)?youtu\.be\/([A-Za-z0-9_-]{11})/,
                     /^(?:https?:\/\/)?(?:www\.)?youtube\.com\/user\/[^\/]+\/?#(?:[^\/]+\/){1,4}([A-Za-z0-9_-]{11})/
                     ]

  def self.video_id(url)
    @@video_regexp.each { |m| return m.match(url)[1] unless m.nil? }
  end
  
  def self.CreateContent(url, user)
    @article = VideoContent.create(:url => url, :created_by => user.id)
    client = YouTubeIt::Client.new
    require 'youtube_it'  
    video_id=self.video_id(url)
    @article.youtube = video_id
    youtube_data = client.video_by(video_id)
    @article.title = youtube_data.title if youtube_data.title
    @article.description = youtube_data.description if youtube_data.description
    @article.thumbnail = youtube_data.thumbnails.first.url if youtube_data.thumbnails.first.url
    @article
  end
  
  def self.saveContent(val,user,ids)
    @article = VideoContent.create(val)
    url = @article.url
    if url.split('v=')[1]
      video_id = (url.split('v=')[1]).split('&')[0]
    elsif url.split('/v/')
      video_id = (url.split('v=')[1]).split('&')[0]
    end
    
    @article.youtube = video_id
    @article.user=user
    @article.save_with_items!(ids) 
    @article
  end
end
