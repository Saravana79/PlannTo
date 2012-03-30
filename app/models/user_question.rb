class UserQuestion < ActiveRecord::Base

  belongs_to :buying_plan
  has_many :user_answers, :through => :user_question_answers
  has_many :user_question_answers, :dependent => :destroy
  accepts_nested_attributes_for :user_question_answers

  validates :question, :presence => true
end
