require "global_utilities" 

module ContentsHelper


  def render_content_type(item,page="")
    case item.type
    when "QuestionContent"
      render :partial => "contents/question", :locals => { :content => item,:page => page }
    when "ReviewContent"
      render :partial => "contents/review", :locals => { :content => item,:page => page }
   when "AnswerContent"
      render :partial => "contents/answer", :locals => { :content => item,:page => page }
    else
      if (item.type == "ArticleContent" && item.url.blank?)
        render :partial => "contents/article", :locals => { :content => item,:page => page }
      elsif (item.type == "ArticleContent" && item.video?)
        render :partial => "contents/video", :locals => {:content => item,:page => page}
      else
        render :partial => "contents/article", :locals => {:content => item,:page => page }
      end
    end
  end

 def change_thumb_original(content, detail='original')
   if content.thumbnail.to_s.include?("/thumb/")
    if(detail == "original")
      return content.content_photos.first.photo.url(:original)
    else
      return content.content_photos.first.photo.url(:medium)
    end
   else
     content.thumbnail.to_s
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
    when "AnswerContent"
      render :partial => "answer_contents/answer_content", :locals => { :answer_content => item }       
    end
  end
  
  def render_new_open_window_form(item,items,content,sub_type,url)
    if url == "true"
     render :partial => "article_contents/article_share", :locals => { :article_content => content,:item => item,:items => items,:content_category => false}
   elsif url == "true" && content!=""
    render :partial => "article_contents/article_share", :locals => { :article_content => content,:item => item,:items => items,:content_category => true}
    
    elsif sub_type == "Q&A" || sub_type == "Q"
     render :partial => "question_contents/new_question_content", :locals => { :content => content,:item => item,:items => items}

    elsif sub_type == "Reviews"
       render :partial => "reviews/review_subcontainer", :locals => { :content => content,:item => item,:items => items}  
    else
              
     render :partial => "article_contents/create_new", :locals => { :content => content,:item => item,:items => items}
    end  
  end
  
  def display_content_form(item)
    case item.type
    when "QuestionContent"
      raw render :partial => "question_contents/new_question_content", :locals => { :content => item }
    when "AnswerContent"
        raw render :partial => "answer_contents/edit_answer", :locals => { :content => item }  
    when "ReviewContent"
      raw render :partial => "reviews/review_subcontainer", :locals => { :content => item }
    else   
      if (item.type == "ArticleContent" && item.url.blank?)
        raw render :partial => "article_contents/create_new", :locals => { :content => item }
      elsif (item.type == "ArticleContent" && item.url != "")
        raw render :partial => "article_contents/article_share", :locals => {:content_category => true,  :content => item}
      elsif (item.type == "ArticleContent" && item.url.nil?)
        raw render :partial => "article_contents/create_new", :locals => { :content => item }
      else
        raw render :partial => "article_contents/article_share", :locals => {:content_category => true, :content => item }
      end
     
    end

  end
   def display_content_form_quick_create(content,item)
    case content.type
    when "QuestionContent"
      raw render :partial => "question_contents/new_question_content", :locals => { :content => content,:item => item }
    when "AnswerContent"
        raw render :partial => "answer_contents/edit_answer", :locals => { :content => content,:item => item }  
    when "ReviewContent"
      raw render :partial => "reviews/review_subcontainer", :locals => { :content => content ,:item => item}
    else   
      if (content.type == "ArticleContent" && content.url.blank?)
        raw render :partial => "article_contents/create_new", :locals => { :content => content,:item => item }
      elsif (content.type == "ArticleContent" && content.url != "")
        raw render :partial => "article_contents/article_share", :locals => {:content_category => true,  :content => content,:item => item}
      elsif (content.type == "ArticleContent" && content.url.nil?)
        raw render :partial => "article_contents/create_new", :locals => { :content => content,:item => item }
      else
        raw render :partial => "article_contents/article_share", :locals => {:content_category => true, :content => content,:item => item }
      end
     
    end

  end
  def render_comments_anchor(item)
    #count = $redis.get("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{item.id}")
    #comment_count = count.nil? ? item.comments_count : count.split("_")[1]
    
    txt= "Comments "
    txt += "(#{item.comments_count})" unless item.comments_count.nil?
    <<-END
     #{link_to txt, content_comments_path(item, :comment_type =>item.class.name), :remote => true, :class => "txt_blue comments_show", :id => "anchor_comments_#{item.id}", :style=>"float:left;padding-left:5px;"}
    END
  end

  def time_ago_format(content)
    if content.is_a?(UserActivity)
      return "0 minutes" if content.try(:time).nil?
      return time_ago_in_words(content.time)
    else  
      return "0 minutes" if content.try(:created_at).nil?
      return time_ago_in_words(content.created_at)
    end  
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
    when "HowTo/Guide" then "Howkb"
    when "Apps" then "Apps"
    when "Books" then "Books"
    when "Comparisons" then "Comparisons"  
    when "Lists" then "Lists"  
    else ""
    end
    return class_name

  end

  def content_write_tab_label(name)
    label = case name
    when "Reviews" then "Write a Review"
    when "Q&A" then "Ask a Question"
    when "Tips" then "Add a Tip"
    when "Accessories" then "Add an Accessory"
    when "Photo" then "Add a Photo"
    when "News" then "Add a Latest News"
    when "Lists" then "Add a List"
    when "Deals" then "Add a Deal"
    when "Event" then "Add an Event"
    when "HowTo/Guide" then "Add a HowTo/Tips"
    when "Book" then "Add a Book"
    when "Apps" then "Add an App"
    when "Travelogue" then "Add a Travelogue"
    when "Comparisons" then "Add a Comparison"  
    else name
    end
    return label
  end

  def content_submit_tab_label(name)
    label = case name
    when "Reviews" then "Submit a Review"
    when "Q&A" then "Submit a FAQ"
    when "Tips" then "Submit a Tip"
    when "Accessories" then "Submit an Accessory"
    when "Photo" then "Submit a Photo"
    when "News" then "Submit a Latest News"
    when "Deals" then "Submit a deal"
    when "Event" then "Submit an Event"
    when "How To/Guides" then "Submit a How To/Guide"
    when "Book" then "Submit a book"
    when "Apps" then "Submit an App"
    when "Video" then "Submit a Video"
    when "HowTo/Guide" then "Submit a HowTo/Tips"
    when "Travelogue" then "Submit a Travelogue"
    when "Lists" then "Submit a List"
    when "Comparisons" then "Submit a Comparison"
    when "Books" then "Submit a Book"
    else ""
    end
    return label
  end

  def get_apps_subcategory_html_list(id, name)
    dropdown = "<select id='#{id}' name='#{name}'><option value='Books'>Books</option><option value='Business & Finance'>Business & Finance</option><option value='Education'>Education</option><option value='Entertainment'>Entertainment</option><option value='Games'>Games</option><option value='Health & Fitness'>Health & Fitness</option><option value='Kids'>Kids</option><option value='Lifestyle'>Lifestyle</option><option value='Music'>Music</option><option value='News'>News</option>"
    dropdown += "<option value='Photography'>Photography</option><option value='Productivity'>Productivity</option><option value='Shopping'>Shopping</option>"
    dropdown += "<option value='Travel'>Travel</option><option value='Utilities'>Utilities</option><option value='Arts & Design'>Arts & Design</option>"
    dropdown += "<option value='Navigation'>Navigation</option><option value='Medical'>Medical</option><option value='Social Networking'>Social Networking</option>"
    dropdown += "<option value='Sports'>Sports</option><option value='Weather'>Weather</option><option value='Video'>Video</option><option value='Media'>Media</option><option value='Personalization'>Personalization</option><option value='Others'>Others</option></select>"
    return dropdown.html_safe
  end
  
    def get_travel_types_html_list(id, name)
    dropdown = "<select id='#{id}' name='#{name}'><option value='Adventure'>Adventure</option><option value='Leisure'>Leisure</option><option value='Religious'>Religious</option><option value='Heritage'>Heritage</option><option value='Honeymoon'>Honeymoon</option><option value='Wildlife'>Wildlife</option>"
    dropdown += "<option value='Others'>Others</option></select>"
    return dropdown.html_safe
  end

  def get_apps_type_html_list(id, name)
    dropdown = "<select id='#{id}' name='#{name}'><option value='Free'>Free</option><option value='Not Free'>Not Free</option></select>"
    return dropdown.html_safe
  end

  def get_books_accessories_subcategory_html_list(id, name)
    dropdown = "<select id='#{id}' name='#{name}'><option value='Bags'> Bags</option><option value='Digital Photo Frame'>Digital Photo Frame</option><option value='Binoculars'> Binoculars</option><option value='Lenses'> Lenses</option><option value='Memory Cards'> Memory Cards</option><option value='Lens Cleaner'> Lens Cleaner</option><option value='Lens Cap'> Lens Cap</option><option value='Lens Hood'> Lens Hood</option><option value='Filters'> Filters</option><option value='Flashes'> Flashes</option><option value='Tripods'> Tripods</option><option value='Monopods'> Monopods</option><option value='Ball Heads'> Ball Heads</option><option value='Straps'> Straps</option><option value='Camera Remote Controls'> Camera Remote Controls</option>"
    dropdown += "<option value='Batteries'> Batteries</option><option value='Chargers'> Chargers</option><option value='Headsets'> Headsets</option><option value='Speakers'> Speakers</option><option value='Case & Covers'> Case & Covers</option><option value='Screen Guards'> Screen Guards</option>"
    dropdown += "<option value='TFT Monitors'> TFT Monitors</option><option value='Lights'> Lights</option><option value='Locks'> Locks</option><option value='Reverse Parking Aid'> Reverse Parking Aid</option><option value='Navigators'> Navigators</option>"
    dropdown += "<option value='Helmets'> Helmets</option><option value='Gears'> Gears</option><option value='Pumps'> Pumps</option><option value='Cycle Computers'> Cycle Computers</option><option value='Cycle Computers'> Cycle Computers</option><option value='Tyres and Tubes'> Tyres and Tubes</option>"
    dropdown += "<option value='Others'> Others</option></select>"
    return dropdown.html_safe
  end


  def get_content_description(content, detail=false)
    wordcount = Content::WORDCOUNT
    if ((content.is_a?(ArticleContent)) && (content.url?)) 
        # encoding: UTF-8
        readmore ="<a class='read_more_class' href=' " + external_content_path(content.id) + "'> Read More</a>"
    else
        readmore = ""
    end
    if detail == false
      "<div class='txt_black_description'>" + Nokogiri::HTML(content.description).text.split[0..(wordcount-1)].join(" ") + (content.description.split.size > wordcount ? "...": "")  + readmore + "</div>"
      #{}"<a href='#{content_path(content.id)}' class='padding_left10 txt_blue'>more...</a>" : "")
    else
      "<div class='txt_black_description_detail'>" + content.description + readmore + "</div>"
    end
  end

  def get_content_title(content)
    if ((content.is_a?(ArticleContent)) && (content.url.blank?) ||  content.is_a?(ReviewContent))
      "<a class='titledetail txt_onhover'>#{content.title }</a>"
    else
      link_to content.title, external_content_path(content.id) , :class => 'titledetail txt_onhover',:target => "_blank"
    end
  end

  def history_redirection_url(id, type)
    return "/history_details?detail_id=#{id}&type=#{type}"
  end

  def get_rating_or_category_contents(content,page="")
    str=""
    if content.sub_type == "#{ArticleCategory::ACCESSORIES}"
     str+= "<label class='txt_black_description_detail'>Category:</label>#{content.field1}<br/>"
    elsif content.sub_type == "#{ArticleCategory::REVIEWS}"
      if(content.is_a?ArticleContent)
        if(content.field1 != '' && content.field1 != '0')
          str+="<label class='txt_black_description_detail' style='font-weight: bold;font-size: 12px;'>Rating :</label><div class ='displayRating' id='content_show_#{content.id}#{page}' data-rating='#{content.field1}'></div><br/>"
        end      
      else
        str=""
        unless content.rating == 0
          str+= "<label class='txt_black_description_detail' style='font-weight: bold;font-size: 12px;'>Rating :</label><div class ='displayRating' id='content_show_#{content.id}#{page}' data-rating='#{content.rating}'></div><br/>"
        end
      end
    end
    return str
  end
  def get_pro_con_verdict(content,page="")
    str=""
    if content.sub_type == "#{ArticleCategory::REVIEWS}"
      if(content.is_a?ArticleContent)
        unless (content.field2.blank? and content.field3.blank? and content.field4.blank?)
          str = "<br clear='all'/><div class ='subContentGap' style='clear:both;border-radius:5px;background-color:rgb(247, 247, 247);padding:10px;margin:10px 0px 10px 0px;'>"

          unless content.field2.blank?
          str+= "<p class='pros'>" + get_content_based_on_words(content.field2,50) + "<p/>"
          end
          unless content.field3.blank? 
           str+= "<p class='cons'>" + get_content_based_on_words(content.field3,50) + "<p/>"
          end 
           unless content.field4.blank? 
           str+= "<p class='verdict'>" + get_content_based_on_words(content.field4,70) + "</p><br/>"
          end 
        str+="</div>"        
        end
        

      else
        str=""
        unless (content.pros.blank? and content.cons.blank?)
          str = "<br/><div class ='subContentGap' style='clear:both;background-color:rgb(247, 247, 247);padding:10px;'>"
          unless content.pros.blank?
            str+= "<p class='pros'>" + get_content_based_on_words(content.pros,100) + "</p><br/>"
          end
          unless content.cons.blank? 
           str+= "<p class='cons'>" + get_content_based_on_words(content.cons,100) + "</label><br/><br/>"
          end 
          str+="</div>"        
        end
      end
    elsif content.sub_type == "#{ArticleCategory::COMPARISONS}"      
      if(content.is_a?ArticleContent)
        unless (content.field4.blank?)
          str = "<br clear='all'/><div class ='subContentGap' style='clear:both;border-radius:5px;background-color:rgb(247, 247, 247);padding:10px;margin:10px 0px 10px 0px;'>"
           unless content.field4.blank? 
             str+= "<p class='verdict'>" + get_content_based_on_words(content.field4,70) + "</p><br/>"
           end 
          str+="</div>"        
        end
      end
    end
    return str
  end


  def display_product_tag(item, display)
    list = "<li id='textTaggers#{item.id}'" + " class='taggingmain'><span><a class='txt_tagging' href="+  item.get_url() + ">" + item.name + "</a>"
    list += "<a id= 'deleteTag' class='icon_close_tagging' href='#'></a>" if display == true
    list += "</span></li>" ;

  end

  def get_anchor_name_link(content)
    first_item = content.items.first
    if (!first_item.nil?)
        content = "<a class='txt_brown_bold' href=" + first_item.get_url() + "> #{first_item.name}</a> "
        return content.html_safe
    end
    
  end
  def indefinite_articlerize(params_word)
    %w(a e i o u).include?(params_word[0].downcase) ? "an #{params_word}" : "a #{params_word}"
  end

  def get_content_based_on_words(params_word,count)
    if (params_word.scan(/\w+/).size > count)
      params_word.split[0..(count-1)].join(" ") + "..."
    else
      params_word
    end
  end

  def positive_vote(user, item)
    # logger.info "==============================#{class_name}"
    vote = user.nil? ? nil : user.fetch_content_user_vote?(item)
    if user
     # class_name = get_voting_class_name(current_user, item)

      link_to "",{:controller => 'votes', :action => "add_vote", :id => item.id, :vote_id => vote,  :parent => "#{GlobalUtilities.get_class_name(item.class.name)}", :vote => :up}, :method => 'POST' , :remote => true, :class  => "current_user_like_unlike", :id => "likeVote#{item.id}"
    else
      link_to "",{:controller => 'votes', :action => "add_vote", :id => item.id, :vote_id => 1,  :parent => "#{GlobalUtilities.get_class_name(item.class.name)}", :vote => :up}, :method => 'POST' , :remote => true, :class => "btn_like_default", :id => "likeVote#{item.id}"
    
    end
      
  end

  def negative_vote(user, item)
    vote = user.nil? ? nil : user.fetch_content_user_vote?(item)
    if user
     # class_name = get_voting_class_name(current_user, item)

      link_to "",{:controller => 'votes', :action => "add_vote", :id => item.id, :vote_id => vote,  :parent => "#{GlobalUtilities.get_class_name(item.class.name)}", :vote => :down}, :method => 'POST' , :remote => true, :class => "current_user_like_unlike", :id => "dislikeVote#{item.id}"
    else
      link_to "",{:controller => 'votes', :action => "add_vote", :id => item.id, :vote_id => nil,  :parent => "#{GlobalUtilities.get_class_name(item.class.name)}", :vote => :down}, :method => 'POST' , :remote => true, :class=> "btn_dislike_default", :id => "dislikeVote#{item.id}"

    end
  end
end
