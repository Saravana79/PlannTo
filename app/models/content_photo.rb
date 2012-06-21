class ContentPhoto < ActiveRecord::Base
  belongs_to :content
  has_attached_file :photo,:styles => { :large => "560x360>", :thumb => "80x60>" },
  :storage => :s3,
  :bucket => ENV['plannto'],
  :s3_credentials => "config/s3.yml",
  :path => "images/content/:id/:style/:filename"
end
