class Guide < ActiveRecord::Base
	has_and_belongs_to_many :contents
end
