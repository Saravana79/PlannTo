class Comment < ActiveRecord::Base

  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true

  default_scope :order => 'created_at DESC'

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  acts_as_voteable

  # NOTE: Comments belong to a user
  belongs_to :user
  #acts_as_voteable

  after_save :update_cache_comments_count
  after_destroy :update_cache_comments_count

  def update_cache_comments_count
    value = $redis.get("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.commentable.id}").split("_")
    $redis.set("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.commentable.id}", "#{value[0]}_#{self.commentable.comments.count}")
  end
end
