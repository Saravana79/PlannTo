class Vote < ActiveRecord::Base
  after_save :update_cache

  scope :for_voter, lambda { |*args| where(["voter_id = ? AND voter_type = ?", args.first.id, args.first.class.name]) }
  scope :for_voteable, lambda { |*args| where(["voteable_id = ? AND voteable_type = ?", args.first.id, args.first.class.name]) }
  scope :recent, lambda { |*args| where(["created_at > ?", (args.first || 2.weeks.ago)]) }
  scope :descending, order("created_at DESC")
  
  belongs_to :voteable, :polymorphic => true
  belongs_to :voter, :polymorphic => true

  attr_accessible :vote, :voter, :voteable

  def update_cache
    redis_key = "user:#{self.voter_id}:content:#{self.voteable_id}:vote"
    vote = $redis.get redis_key
    $redis.set(redis_key, true) if self.vote?
    $redis.set(redis_key, false) if !self.vote?
    if self.vote == ""
      $redis.del(redis_key) if !vote.nil?
    end
  end


  # Comment out the line below to allow multiple votes per user.
  #  validates_uniqueness_of :voteable_id, :scope => [:voteable_type, :voter_type, :voter_id]
  

end