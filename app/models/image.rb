class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  has_attached_file :avatar,
      :storage => :s3,
      :s3_credentials => "#{Rails.root}/config/s3.yml",
      :styles => lambda { |a| a.instance.set_styles },
      :path => ":img_table_name/:imgeable_type/:style/:filename",
      :url  => ":s3_sg_url"


  before_save :update_avatar_file_name
  after_save :update_item_imageurl

  def self.file_dimensions(image)
    hieght_width = image.ad_size.split("x")
    dimensions = Paperclip::Geometry.from_file(image.avatar.queued_for_write[:original].path)
    logger.info "===========================================#{dimensions.width} +++++++++++++++#{dimensions.height}"
    return_val = true
    if dimensions.width.to_i.to_s != hieght_width[0] || dimensions.height.to_i.to_s != hieght_width[1]
      #errors.add :file, "Width must be #{hieght_width[0]}px and height must be #{hieght_width[1]}px"
      return_val = false
    end
    return return_val
  end

  def base_url
    if self.avatar.blank?
      ""
    else
      configatron.root_image_path + self.avatar.path
    end
  end

  def set_styles
    if self.imageable_type == "Item"
      { :original => ["100%", :jpeg], :medium => ["176x132", :jpeg], :small => ["40x30", :jpeg] }
    else
      { :original => ["100%", :jpeg] }
    end
  end

  private

  def update_item_imageurl
    if imageable_type == "Item"
      item = imageable
      item.imageurl = avatar_file_name
      item.save!
    end
  end

  def update_avatar_file_name
    name = self.avatar_file_name.to_s.split(".")
    name[1] = "jpeg"
    self.avatar_file_name = name.join(".")
  end
end
