class ItemSpecificationSummaryList < ActiveRecord::Base
	belongs_to :item_type
	belongs_to :attribute

	attr_protected :sortorder

end
