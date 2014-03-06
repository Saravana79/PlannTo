class Advertisement < ActiveRecord::Base
   validates_presence_of :name
   validates_presence_of :click_url
   has_attached_file :upload_image, 
                     :styles => {  :medium => "120x120>", :thumb => "24x24>" },
                     :storage => :s3,
                     :bucket => ENV['planntonew'],
                     :s3_credentials => "config/s3.yml",
                     :path => "images/advertisements/:id/:style/:filename",
                     :url  => ":s3_sg_url"
   belongs_to :content

   validate :file_dimensions 

   def self.url_params_process(param)
     url_params = "Params = "
     param = param.reject {|s| ["controller", "action"].include?(s)}
     keys = param.keys
     values = param.values

     [*0...keys.count].each do |each_val|
       url_params = url_params + "#{keys[each_val]}-#{values[each_val]};"
     end
     return url_params
   end

   def self.process_size(width)
     width = width.to_i
     if (width < 150)
       return_val = 120
     elsif (width < 350)
       return_val = 300
     elsif (width < 750)
       return_val = 728
     else
       return_val = 120
     end
     return return_val
   end

   private

   def file_dimensions
         hieght_width = self.ad_size.split("*")
         dimensions = Paperclip::Geometry.from_file(upload_image.queued_for_write[:original].path)
         logger.info "===========================================#{dimensions.width} +++++++++++++++#{dimensions.height}"
         if dimensions.width.to_i.to_s != hieght_width[0] || dimensions.height.to_i.to_s != hieght_width[1]
            errors.add :file, "Width must be #{hieght_width[0]}px and height must be #{hieght_width[1]}px"
         end
   end

end
