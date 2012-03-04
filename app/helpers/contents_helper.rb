module ContentsHelper

  def render_content_type(item)
    case item.type
    when "ArticleContent" 
      render :partial => "contents/article", :locals => { :content => item }
    when "VideoContent" 
      render :partial => "contents/video", :locals => { :content => item }
    when "QuestionContent" 
      render :partial => "contents/question", :locals => { :content => item }  
    end
  end
  
  def render_comments_anchor(item)
    txt= "Comments ( #{item.comments.count})"
    <<-END
     #{link_to txt, content_comments_path(item), :remote => true, :class => "txt_blue comments_show", :id => "anchor_comments_#{item.id}"}
    END
  end

end
