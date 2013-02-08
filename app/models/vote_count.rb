class VoteCount < ActiveRecord::Base
  after_save :update_cache
  require 'global_utilities'
  REDIS_CONTENT_VOTE_KEY_PREFIX = "content_vote_count_"
  REDIS_BUYING_PLAN_VOTE_KEY_PREFIX = "buying_plan_vote_count_"
  REDIS_ANSWER_VOTE_KEY_PREFIX = "user_answer_vote_count_"
  # scope :order_by_votes, lambda { |*args| where(["voteable_type = ?", args.first.class.name]).order(:vote_count) }
  scope :search_vote, lambda {|voteable| where("voteable_id = ? and voteable_type = ?", voteable.id, GlobalUtilities.get_class_name(voteable.class.name)) }


  belongs_to :voter, :polymorphic => true
  belongs_to :voteable, :polymorphic => true

  def update_cache
    count = self.vote_count_positive - self.vote_count_negative
    if self.voteable_type == "Content"
      #update content table
      self.voteable.update_attributes(:no_of_votes => self.voteable.votes.count, :positive_votes => #self.vote_count_positive, :negative_votes => self.vote_count_negative, :total_votes => count, :comments_count => self.comment_count)
      self.vote_count_positive, :negative_votes => self.vote_count_negative, :total_votes => count)
    end
    
    redis_key_prefix = get_cache_prefix
    $redis.set("#{redis_key_prefix}#{self.voteable_id}", count)
  end

  def get_cache_prefix
    case GlobalUtilities.get_class_name(voteable.class.name)
    when "Content" then REDIS_CONTENT_VOTE_KEY_PREFIX
    when "BuyingPlan" then REDIS_BUYING_PLAN_VOTE_KEY_PREFIX
    when "UserAnswer" then REDIS_ANSWER_VOTE_KEY_PREFIX
    end
  end
end
