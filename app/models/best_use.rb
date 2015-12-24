class Best_Use < ActiveRecord::Base
  has_many :debates, :as => :argument
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'
end

