class Comment < ActiveRecord::Base

  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true

  default_scope :order => 'created_at DESC'
  
  DELETE_STATUS = 5

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  acts_as_voteable
  has_many :reports, :as => :reportable, :dependent => :destroy 
  
  # NOTE: Comments belong to a user
  belongs_to :user
  #acts_as_voteable

  after_save :update_cache_comments_count
  after_destroy :update_cache_comments_count

  def update_cache_comments_count
    cached_value = $redis.get("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.commentable_id}")
    comments_count = self.commentable.comments.where("status =1").count
   
    unless cached_value.nil?
      value = cached_value.split("_")      
    $redis.set("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.commentable.id}", "#{value[0]}_#{comments_count}")
    
  end
  self.commentable.update_attributes(:comments_count => comments_count)

  end
  
  def set_comment_status(type)
    status = case type
    when "create" then 1
    when "update" then 1
    else
    1
    end
    return status
  end
  def can_update_content?(current_user)
    return false if !current_user
    return false if current_user.id != self.user_id
    return true
  end
end
