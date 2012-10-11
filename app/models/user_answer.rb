class UserAnswer < ActiveRecord::Base
  acts_as_commentable
  has_many :recommendations
  has_many :recommended_items, :class_name => "Item", :through => :recommendations

  has_many :user_questions, :through => :user_question_answers
  has_many :user_question_answers
  belongs_to :user

  validates :answer, :presence => true
end
