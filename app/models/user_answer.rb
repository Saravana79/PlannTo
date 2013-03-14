class UserAnswer < ActiveRecord::Base
  acts_as_commentable
  has_many :recommendations
  has_many :recommended_items, :class_name => "Item", :through => :recommendations

  has_many :user_questions, :through => :user_question_answers
  has_many :user_question_answers
  belongs_to :user

  validates :answer, :presence => true
  
   def content_vote_count
    count = $redis.get("#{VoteCount::REDIS_ANSWER_VOTE_KEY_PREFIX}#{self.id}")
    if count.nil?
      vote = VoteCount.search_vote(self).first
      count = vote.nil? ? 0 : (vote.vote_count_positive - vote.vote_count_negative)
      $redis.set("#{VoteCount::REDIS_ANSWER_VOTE_KEY_PREFIX}#{self.id}", count)
      return count
    else
      return count
    end
  end
end
