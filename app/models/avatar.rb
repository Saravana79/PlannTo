class Avatar < ActiveRecord::Base
  belongs_to :user
  has_attached_file :photo, :styles => { :medium => "300x300>", :thumb => "100x100>", :small => "25x25>" }

end
