class ImpressionMissing < ActiveRecord::Base
  validates_uniqueness_of :hosted_site_url
  def self.create_or_update_impression_missing(tempurl, type="PriceComparison")
    impression = ImpressionMissing.where(:hosted_site_url => tempurl, :req_type => type).first_or_initialize
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
