class Question < ActiveRecord::Base
  has_many :answers
  has_many :answer_contents
  belongs_to :user, :foreign_key => :created_by

  acts_as_commentable
  acts_as_taggable
  acts_as_voteable
  #acts_as_taggable_on :skills, :interests
  
  def self.sort_by_vote_count
    includes(:vote_count).order('vote_counts.vote_count DESC')
  end
  
end
