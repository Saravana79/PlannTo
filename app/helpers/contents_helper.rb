module ContentsHelper

  def render_content_type(item)
    case item.type
    when "ArticleContent"
      render :partial => "contents/article", :locals => { :content => item }
    when "VideoContent"
      render :partial => "contents/video", :locals => { :content => item }
    when "QuestionContent"
      render :partial => "contents/question", :locals => { :content => item }
    when "ReviewContent"
      render :partial => "contents/review", :locals => { :content => item }
    when "EventContent"
      render :partial => "contents/event", :locals => { :content => item }
    when "PlanntoContent"
      render :partial => "contents/default", :locals => { :content => item }
    end
  end

  def display_content_type(item)
    case item.type
    when "ArticleContent"
      render :partial => "contents/show_default", :locals => { :content => item }
    when "VideoContent"
      render :partial => "contents/show_default", :locals => { :content => item }
    when "QuestionContent"
      render :partial => "contents/show_question_details", :locals => { :content => item }
    when "ReviewContent"
      render :partial => "contents/show_default", :locals => { :content => item }
    when "EventContent"
      render :partial => "contents/show_default", :locals => { :content => item }
    when "PlanntoContent"
      render :partial => "contents/show_default", :locals => { :content => item }
    end
  end
  
  def render_comments_anchor(item)
    txt= "Comments ( #{item.comments.count})"
    <<-END
     #{link_to txt, content_comments_path(item), :remote => true, :class => "txt_blue comments_show", :id => "anchor_comments_#{item.id}"}
    END
  end

  def time_ago_format(content)
    return "0 minutes" if content.try(:updated_at).nil?
    return time_ago_in_words(content.updated_at)
  end

  def get_content_container_class(article_category)
    class_name = case article_category
    when "Reviews" then "Review"
    when "Q&A" then "Qatab"
    when "Tips" then "Tips"
    when "Photo" then "Photos"
    when "Accessories" then "Accessories"
    when "News" then "News"
    when "Deals" then "Deals"
    when "Travelogue" then "Travelogue"
    when "Video" then "Video2"
    when "Event" then "Event"
    when "HowTo/KB" then "Howkb"
    when "Apps" then "Apps"
    when "Books" then "Books"
    else ""
    end
    return class_name

  end

  def content_write_tab_label(name)
    label = case name
    when "Reviews" then "Write a Review"
    when "Q&A" then "Ask a Question"
    when "Tips" then "Add a Tip"
    when "Accessories" then "Add a Accessory"
    when "Photo" then "Add a Photo"
    when "News" then "Add a News"
    when "Deals" then "Add a deal"
    when "Event" then "Add a Event"
    when "How To/KBs" then "Add a HowTo/KB"
    when "Book" then "Add a Book"
    when "Apps" then "Add an Apps"
    else ""
    end
    return label
  end

  def content_submit_tab_label(name)
    label = case name
    when "Reviews" then "Submit a Review"
    when "Q&A" then "Submit a Questions & Answer"
    when "Tips" then "Submit a Tip"
    when "Accessories" then "Submit an Accessory"
    when "Photo" then "Submit a Photo"
    when "News" then "Submit a Latest News"
    when "Deals" then "Submit a deal"
    when "Event" then "Submit a Event"
    when "How To/KBs" then "Submit a HowTo/KB"
    when "Book" then "Submit a book"
    when "Apps" then "Submit an Apps"
    else ""
    end
    return label
  end

  def get_apps_subcategory_html_list
    dropdown = "<select id='article_content_field1' name='article_content[field1]'><option value='Books'>Books</option><option value='Business & Finance'>Business & Finance</option><option value='Education'>Education</option><option value='Entertainment'>Entertainment</option><option value='Games'>Games</option><option value='Health & Fitness'>Health & Fitness</option><option value='Kids'>Kids</option><option value='Lifestyle'>Lifestyle</option><option value='Music'>Music</option><option value='News'>News</option>"
    dropdown += "<option value='Photography'>Photography</option><option value='Productivity'>Productivity</option><option value='Shopping'>Shopping</option>"
    dropdown += "<option value='Travel'>Travel</option><option value='Utilities'>Utilities</option><option value='Arts & Design'>Arts & Design</option>"
    dropdown += "<option value='Navigation'>Navigation</option><option value='Medical'>Medical</option><option value='Social Networking'>Social Networking</option>"
    dropdown += "<option value='Sports'>Sports</option><option value='Weather'>Weather</option></select>"
    return dropdown.html_safe
  end

  def get_apps_type_html_list
    dropdown = "<select id='article_content_field2' name='article_content[field2]'><option value='Free'>Free</option><option value='Not Free'>Not Free</option></select>"
    return dropdown.html_safe
  end

  def get_books_accessories_subcategory_html_list
    dropdown = "<select id='article_content_field1' name='article_content[field1]'><option value='Books'>Books</option><option value='Business & Finance'>Business & Finance</option><option value='Education'>Education</option><option value='Entertainment'>Entertainment</option><option value='Games'>Games</option><option value='Health & Fitness'>Health & Fitness</option><option value='Kids'>Kids</option><option value='Lifestyle'>Lifestyle</option><option value='Music'>Music</option><option value='News'>News</option>"
    dropdown += "<option value='Photography'>Photography</option><option value='Productivity'>Productivity</option><option value='Shopping'>Shopping</option>"
    dropdown += "<option value='Travel'>Travel</option><option value='Utilities'>Utilities</option><option value='Arts & Design'>Arts & Design</option>"
    dropdown += "<option value='Navigation'>Navigation</option><option value='Medical'>Medical</option><option value='Social Networking'>Social Networking</option>"
    dropdown += "<option value='Sports'>Sports</option><option value='Weather'>Weather</option></select>"
    return dropdown.html_safe
  end

end
