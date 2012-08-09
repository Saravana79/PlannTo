class ContentPhoto < ActiveRecord::Base
  belongs_to :content
  has_attached_file :photo,:styles => { :medium => "120x90>", :thumb => "80x60>" },
  :storage => :s3,
  :bucket => ENV['plannto'],
  :s3_credentials => "config/s3.yml",
  :path => "images/content/:id/:style/:filename"
  
  def self.save_url_content_to_local(article)
    photo = ContentPhoto.new
    extname = File.extname(article.thumbnail).delete("%")
    basename = File.basename(article.thumbnail, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode
    open(URI.parse(article.thumbnail)) do |data|  
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
    extname = File.extname(article.thumbnail).delete("%")
    basename = File.basename(article.thumbnail, extname).delete("%")
    file = Tempfile.new([basename, extname])
    file.binmode  
    open(URI.parse(article.thumbnail)) do |data|  
      file.write data.read
    end
    file.rewind
    photo.photo = file
    photo.save 
    rescue
     return true
  end
end
