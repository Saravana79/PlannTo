class UserQuestionAnswer < ActiveRecord::Base
  belongs_to :user_question
  belongs_to :user_answer
end
