class ContentPhoto < ActiveRecord::Base
  belongs_to :content
  has_attached_file :photo,:styles => { :medium => "120x90!", :thumb => "80x60!" },
  :storage => :s3,
  :bucket => ENV['plannto'],
  :s3_credentials => "config/s3.yml",
  :path => "images/content/:id/:style/:filename"
  
  def self.save_url_content_to_local(article)
    photo = ContentPhoto.new
    safe_thumbnail_url = URI.encode(URI.decode(article.thumbnail))
    extname = File.extname(safe_thumbnail_url).delete("%")
    basename = File.basename(safe_thumbnail_url, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode
    open(URI.parse(safe_thumbnail_url)) do |data|  
      file.write data.read
    end
    file.rewind
    photo.url = article.thumbnail
    photo.photo = file
    photo.content_id = article.id
    photo.save
    rescue 
     return true
  end

  def self.update_url_content_to_local(article)
    photo = article.content_photos.first
    safe_thumbnail_url = URI.encode(URI.decode(article.thumbnail))
    extname = File.extname(safe_thumbnail_url).delete("%")
    basename = File.basename(safe_thumbnail_url, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode  
    open(URI.parse(safe_thumbnail_url)) do |data|  
      file.write data.read
    end
    file.rewind
    unless photo.nil?
      photo.url = article.thumbnail
      photo.photo = file
      photo.save
    else
      cp = ContentPhoto.new
      cp.content_id = article.id
      cp.url = article.thumbnail
      cp.photo = file
      cp.save
    end     
    rescue
     return true
  end
end
