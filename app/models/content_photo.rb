class ContentPhoto < ActiveRecord::Base
  belongs_to :content
  has_attached_file :photo,:styles => { :large => "560x360>", :thumb => "80x60>" },
  :storage => :s3,
  :bucket => ENV['plannto'],
  :s3_credentials => "config/s3.yml",
  :path => "images/content/:id/:style/:filename"
  
  def self.save_url_content_to_local(article)
    photo = ContentPhoto.new
    safe_thumbnail_url = URI.encode(article.thumbnail, "[],{},()")
    extname = File.extname(safe_thumbnail_url).delete("%")
    basename = File.basename(safe_thumbnail_url, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode
    open(URI.parse(safe_thumbnail_url)) do |data|  
      file.write data.read
    end
    file.rewind
    photo.photo = file
    photo.content_id = article.id
    photo.save
    rescue 
     return true
  end

  def self.update_url_content_to_local(article)
    photo = article.content_photo
    safe_thumbnail_url = URI.encode(article.thumbnail, "[],{},()")
    extname = File.extname(safe_thumbnail_url).delete("%")
    basename = File.basename(safe_thumbnail_url, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode  
    open(URI.parse(safe_thumbnail_url)) do |data|  
      file.write data.read
    end
    file.rewind
    photo.photo = file
    photo.save 
    rescue
     return true
  end
end
