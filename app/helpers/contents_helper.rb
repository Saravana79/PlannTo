module ContentsHelper

  def render_content_type(item)
    case item.type
    when "ArticleContent" 
      render :partial => "contents/article", :locals => { :content => item }
    when "VideoContent" 
      render :partial => "contents/video", :locals => { :content => item }
    end
  end
end
