class ImpressionMissing < ActiveRecord::Base
  def self.create_or_update_impression_missing(tempurl)
    impression = ImpressionMissing.find_or_create_by_hosted_site_url_and_req_type(tempurl, "PriceComparison")
    if impression.new_record?
      impression.update_attributes(created_time: Time.zone.now, updated_time: Time.zone.now)
    else
      impression.update_attributes(updated_time: Time.zone.now, :count => impression.count + 1)
    end

    impression
  end
end
