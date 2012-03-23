class BuyingPlan < ActiveRecord::Base
  include Extensions::UUID

  has_one :user_question
  belongs_to :user
  belongs_to :itemtype

  def content_vote_count
    count = $redis.get("#{VoteCount::REDIS_BUYING_PLAN_VOTE_KEY_PREFIX}#{self.id}")
    if count.nil?
      vote = VoteCount.search_vote(self).first
      count = vote.nil? ? 0 : (vote.vote_count_positive - vote.vote_count_negative)
      $redis.set("#{VoteCount::REDIS_BUYING_PLAN_VOTE_KEY_PREFIX}#{self.id}", count)
      return count
    else
      return count
    end
  end
end
