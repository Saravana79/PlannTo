class Avatar < ActiveRecord::Base
  belongs_to :user
  has_attached_file :photo, 
  :styles => {  :medium => "120x120>", :thumb => "24x24>" },
  :storage => :s3,
  :bucket => ENV['planntonew'],
  :s3_credentials => "config/s3.yml",
  :path => "images/users/:id/:style/:filename",
  :url  => ":s3_sg_url"

end
