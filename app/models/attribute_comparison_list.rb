class AttributeComparisonList < ActiveRecord::Base

	belongs_to :attribute
	belongs_to :itemtype

	attr_accessible :title, :attribute_id, :iremtype_id, :value, :condition, :description

	ORDER = {"GreaterThan" => {value: "desc", first: -2, second: -1},
			 "LeserThan" => {value: "asc", first: 0, second: 1},
			 "Equal" => {value: "eq", first: 0, second: 1}}

	def order
		return ORDER[self.condition]
	end
end
