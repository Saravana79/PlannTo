class ImpressionMissing < ActiveRecord::Base
  validates_uniqueness_of :hosted_site_url
  def self.create_or_update_impression_missing(tempurl, type="PriceComparison")
    impression = ImpressionMissing.find_or_initialize_by_hosted_site_url_and_req_type(tempurl, type)
    if impression.new_record?
      impression.count = 1
      impression.save
    else
      # impression.update_attributes(:count => impression.count + 1)
      ActiveRecord::Base.connection.execute("update impression_missings set count=count+1 where id=#{impression.id}")
    end

    impression
  end
end
