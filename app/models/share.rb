class Share < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
  belongs_to :share_type
  has_attached_file :image,
    :styles => {
      :thumb=> "100x100#",
      :small  => "150x150>" }
  acts_as_voteable    
end
