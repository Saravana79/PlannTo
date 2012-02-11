class Content < ActiveRecord::Base
	belongs_to :user, :foreign_key => 'updated_by'
	belongs_to :user, :foreign_key => 'created_by'
	
	acts_as_commentable
	acts_as_voteable

end
