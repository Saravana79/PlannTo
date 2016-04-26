class ImpressionMissing < ActiveRecord::Base
  def self.create_or_update_impression_missing(tempurl, type="PriceComparison")
    impression = ImpressionMissing.find_or_initialize_by_hosted_site_url_and_req_type(tempurl, type)
    if impression.new_record?
      impression.count = 1
      impression.save
    else
      impression.update_attributes(:updated_time => Time.zone.now, :count => impression.count + 1)
    end

    impression
  end
end
