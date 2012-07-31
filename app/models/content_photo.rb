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
    extname = File.extname(url)
    basename = File.basename(url, extname)
    file = Tempfile.new([basename, extname])
    file.binmode
    open(URI.parse(url)) do |data|  
      file.write data.read
    end
    file.rewind
    photo.photo = file
    photo.url = url
    photo.save
  end
 
  def self.update_url_content_to_local(article,url)
    photo = ContentPhoto.find_by_url(url)
    photo.content_id = article.id
    photo.save
   end
 end   
