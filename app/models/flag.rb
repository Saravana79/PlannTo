class Flag < ActiveRecord::Base
	belongs_to :content
	belongs_to :flagged_by, :class_name => 'User', :foreign_key => 'flagged_by'
	belongs_to :verified_by, :class_name => 'User', :foreign_key => 'verified_by'
end
