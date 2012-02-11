class UserImage < ActiveRecord::Base
  has_attached_file :uploaded_image, :styles => { :medium => "300x300>", :thumb => "100x100>" }
end
