class Point < ActiveRecord::Base
  require 'global_utilities'
  #include GlobalUtilities

  scope :search_item, lambda {|object, user| where("object_id = ? and object_type = ? and user_id = ?", object.id, GlobalUtilities.get_class_name(object.class.name), user.id) }

  module PointReason
    CONTENT_CREATE = "content_create"
    CONTENT_SHARE = "content_share"
    USER_LOG_IN = "user_login_in"
    VOTE = "vote"
    CONTENT_COMMENT = "content_comment"
  end

  module CategoryName
    TIP = "Tip"
    REVIEW = "Review"
    ARTICLE_CONTENT = "ArticleContent"
    Q_AND_A = "Q&A"
  end

  SHARED_CATEGORY_LIST = ["Tip", "Review", "ArticleContent", "Q&A"]

  module CreationPoint
    DEFAULT_CREATE_POINT = 2
    REVIEW_POINT = 2
    TIPS_POINT = 2
    DEFAULT_SHARE_POINT = 1
    SHARE_ARTICLE_POINT = 1
    SHARE_REVIEW_POINT = 1
    SHARE_TIPS_POINT = 1
    SHARE_VIDEO_POINT = 1
    ASK_QUESTION_POINT = 1
    ANSWER_QUESTION_POINT = 2
    COMMENT_POINT=1
    VOTE_POINT=0.1
  end

  module PercentagePoint
    PLANNTO_CONTENT_VOTE_PER = 20
    OTHER_CONTENT_VOTE_PER = 10
  end

  def self.get_points(object, reason)
    points = 0
    if reason == Point::PointReason::CONTENT_CREATE
      class_name = GlobalUtilities.get_class_name(object.class.name)
      points = case class_name
      when Point::CategoryName::TIP then Point::CreationPoint::TIPS_POINT
      when Point::CategoryName::REVIEW then Point::CreationPoint::REVIEW_POINT
      else Point::CreationPoint::DEFAULT_CREATE_POINT
      end
    elsif reason == Point::PointReason::CONTENT_SHARE
      #category = object.article_category.name
      category = object.class.name
      points = case category
      when Point::CategoryName::TIP then Point::CreationPoint::SHARE_TIPS_POINT
      when Point::CategoryName::REVIEW then Point::CreationPoint::SHARE_REVIEW_POINT
      else Point::CreationPoint::DEFAULT_SHARE_POINT
      end 
   
   elsif reason == Point::PointReason::VOTE
     return Point::CreationPoint::VOTE_POINT
   elsif reason == Point::PointReason::CONTENT_COMMENT
      return Point::CreationPoint::COMMENT_POINT 
    end  
    return points
  end


  def self.add_point_system(user, object, reason)
    point = Point.search_item(object, user).first
    points = Point.get_points(object, reason)
      Point.create(:user_id => user.id, :object_type => GlobalUtilities.get_class_name(object.class.name), :object_id => object.id, :reason => reason, :points => points)
  end

  def self.get_per_value(object)
    if SHARED_CATEGORY_LIST.include?(object.type)
      return Point::PercentagePoint::OTHER_CONTENT_VOTE_PER
    else
      return Point::PercentagePoint::PLANNTO_CONTENT_VOTE_PER
    end
  end

  def self.add_voting_point(user, object,type)
    vote_count = VoteCount.search_vote(object).first
    points = Point.get_points(object, Point::PointReason::VOTE)
    point = Point.search_item(object, user).first
    Point.create_or_find_by(:user_id => user.id, :object_type => GlobalUtilities.get_class_name(object.class.name), :object_id => object.id, :reason =>  Point::PointReason::VOTE, :points => points.to_f)
  end

  def self.calculate_voting_points(total, variance)
    value = total.to_f
    # points = (value - (value*variance)/100).round(2)
    points = (value / (value*variance)/100)
    return points
  end

  #Content Creation Part

  #Review  - 2 points
  #Tips    - 2 points


  #Sharing an external article, review, tips,video - 1 point

  #Asked a question - 1 point
  #Answered a question  - 2 points


  #If the content gets

  #we can provide 20% and 10% as points for user created content and user shared content.

  #Same way we need to reduce the 10% for the negative points for both content created in our and content created outside our side.


  #If user voted

  #10 votes - he will get 1 point
  #50 votes - he will get 5 point
  #100 votes - he will get 10 point
  #Basically we can give 10% of votes as points.
end
