class VoteCount < ActiveRecord::Base
  after_save :update_cache
  require 'global_utilities'
  REDIS_CONTENT_VOTE_KEY_PREFIX = "content_vote_count_"
  # scope :order_by_votes, lambda { |*args| where(["voteable_type = ?", args.first.class.name]).order(:vote_count) }
  scope :search_vote, lambda {|voteable| where("voteable_id = ? and voteable_type = ?", voteable.id, GlobalUtilities.get_class_name(voteable.class.name)) }


  belongs_to :voter, :polymorphic => true
  belongs_to :voteable, :polymorphic => true

  def update_cache
    count = self.vote_count_positive - self.vote_count_negative
    $redis.set("#{REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.voteable_id}", count)
  end
end
