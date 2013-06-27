class ProConCategory < ActiveRecord::Base
	belongs_to :itemtype
	has_many :item_pro_cons
end
