require "open-uri"
class ImageContent < Content
  acts_as_citier
  has_attached_file :image_content, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  
  def picture_from_url(url)
      self.image_content = open(url)
    end
end
