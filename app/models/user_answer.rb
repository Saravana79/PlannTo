class UserAnswer < ActiveRecord::Base
  has_many :recommendations
  has_many :user_questions, :through => :user_question_answers
  has_many :user_question_answers

  validates :answer, :presence => true
end
