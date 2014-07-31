class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  has_attached_file :avatar,
      :storage => :s3,
      :s3_credentials => "#{Rails.root}/config/s3.yml",
      :path => "images/advertisements/:imageable_id/:id/:filename",
      :url  => ":s3_sg_url"

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
end
