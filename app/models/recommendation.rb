class Recommendation < ActiveRecord::Base
  belongs_to :item
  belongs_to :user_answer
end
