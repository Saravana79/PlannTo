class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  has_attached_file :avatar,
      :storage => :s3,
      :s3_credentials => "#{Rails.root}/config/s3.yml",
      :styles => lambda { |a| a.instance.set_styles },
      :path => ":image_prefix_path/:style/:filename",
      :url  => ":s3_sg_url",
      :convert_options => { :medium => "-gravity center -extent 176x132", :small => "-gravity center -extent 40x30"}


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
    format = self.avatar_content_type.include?("gif") ? :gif : :jpeg
    if ((self.imageable_type == "Item" || self.imageable_type == "Itemdetail"))
      { :original => ["100%", format], :medium => ["176x132>", format], :small => ["40x30>", format] }
    else
      { :original => ["100%", format] }
    end
  end

  def set_convert_options
    if self.imageable_type == "Item" || self.imageable_type == "Itemdetail"
      { :medium => "-gravity center -extent 176x132", :small => "-gravity center -extent 40x30"}
    else
      {}
    end
  end

  private

  def update_item_imageurl
    if imageable_type == "Item"
      item = imageable
      item.imageurl = avatar_file_name
      item.save!
    elsif imageable_type == "Itemdetail"
      item_detail = imageable
      item_detail.Image = avatar_file_name
      item_detail.save!
    end
  end

  def update_avatar_file_name
    if !self.avatar_content_type.include?("gif")
      name = self.avatar_file_name.to_s.split(".")
      name = name[0...name.size-1]
      name = name.join(".") + ".jpeg"
      self.avatar_file_name = name
    end
  end
end
