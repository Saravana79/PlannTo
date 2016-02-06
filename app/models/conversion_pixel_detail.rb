class ConversionPixelDetail < ActiveRecord::Base

  def self.update_conversion_pixel_detail_from_clicks
    clicks = Click.where(:advertisement_id => 83)

    clicks.each do |click|
      conversion_pixel_details = ConversionPixelDetail.where(:plannto_user_id => click.temp_user_id, :from_plannto => false)
      conversion_pixel_details.each do |conversion_pixel_detail|
        conversion_pixel_detail.from_plannto = true
        conversion_pixel_detail.save
      end
    end
  end
end
