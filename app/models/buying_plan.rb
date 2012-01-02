class BuyingPlan < ActiveRecord::Base
  include Extensions::UUID

  has_one :user_question
  belongs_to :itemtype
end
