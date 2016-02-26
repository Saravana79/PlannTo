class ItemDetailOtherMapping < ActiveRecord::Base
  belongs_to :item_detail_other
  validates_uniqueness_of :item_detail_other_id, :item_id
end
