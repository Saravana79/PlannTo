class AdHourlySpentDetail < ActiveRecord::Base

  def self.create_ad_houly_spent_detail(param)
    # create ad hourly spent detail
    ad_hourly_spent_detail = AdHourlySpentDetail.where(:advertisement_id => param["advertisement_id"], :spent_date => param["spent_date"], :hour => param["hour"]).first_or_initialize
    ad_hourly_spent_detail.update_attributes(:time_usage => param["time_usage"])
  end
end
