class ContentPhoto < ActiveRecord::Base
  require 'rubygems'
  require 'open-uri'
  require 'paperclip'
  belongs_to :content
  has_attached_file :photo,:styles => { :large => "560x360>", :thumb => "100x100>", :small  => "90x120>" },
    :storage => :s3,
    :bucket => ENV['plannto'],
    :s3_credentials => "config/s3.yml",
    :path => "images/content/:id/:style/:filename"
  
  def self.save_url_content_to_local(article,url)
    photo = ContentPhoto.new
    photo.photo= open(url)
    photo.content_id = article.id
    photo.save
    @article.update_attribute('thumbnail',@article.content_photo.photo.url)
 end
end   
