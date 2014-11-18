class AdHourlySpentDetail < ActiveRecord::Base

  def self.create_ad_houly_spent_detail(param)
    # create ad hourly spent detail
    ad_hourly_spent_detail = AdHourlySpentDetail.find_or_initialize_by_advertisement_id_and_spent_date_and_hour(param["advertisement_id"], param["spent_date"], param["hour"])
    ad_hourly_spent_detail.update_attributes(:time_usage => param["time_usage"])
  end
end
