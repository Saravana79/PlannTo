class TopicItemtypeRelation < ActiveRecord::Base
  belongs_to :topic,:foreign_key => 'item_id'
  belongs_to :itemtype
end
