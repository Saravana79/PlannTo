class VideoContent < ArticleContent
  acts_as_citier
  validates_uniqueness_of :youtube
  def self.CreateContent(url, user)
    @article = VideoContent.create(:url => url, :created_by => user.id)
    client = YouTubeIt::Client.new
    require 'youtube_it'  
    if url.split('v=')[1]
      video_id = (url.split('v=')[1]).split('&')[0]
    elsif url.split('/v/')
      video_id = (url.split('v=')[1]).split('&')[0]
    end
    @article.youtube = video_id
    youtube_data = client.video_by(video_id)
    @article.title = youtube_data.title if youtube_data.title
    @article.description = youtube_data.description if youtube_data.description
    @article.thumbnail = youtube_data.thumbnails.first.url if youtube_data.thumbnails.first.url
    @article
  end
end
