class Answer < ActiveRecord::Base
  belongs_to :answers
  belongs_to :user, :foreign_key => :created_by

  acts_as_commentable
  acts_as_voteable
  
  def self.sort_by_vote_count
    includes(:vote_count).order('vote_counts.vote_count DESC')
  end
  
end
