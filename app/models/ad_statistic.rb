class AdStatistic < ActiveRecord::Base

  def self.process_ad_statistic()
    process_ad_statistic_for_day(Date.today)
    process_ad_statistic_for_day(Date.yesterday, true)
  end

  def self.process_ad_statistic_for_day(date, is_del=false)
    day = date.day
    redis_keys = get_redis_keys(day)

    redis_values = $redis_rtb.pipelined do
      redis_keys.each do |each_key|
        $redis_rtb.get(each_key)
      end
    end

    redis_keys.each_with_index do |each_key, index|
      value = redis_values[index]
      if !value.blank?
        event_type = each_key.to_s.split(":").last(2)[0]
        ad_statistic = AdStatistic.find_or_initialize_by_event_date_and_event_type(:event_date => date, :event_type => event_type)
        ad_statistic.update_attributes(:count => value)
      end
    end

    if is_del == true
      $redis_rtb.pipelined do
        redis_keys.each do |each_key|
          $redis_rtb.del(each_key)
        end
      end
    end
  end

  def self.get_redis_keys(day)
    redis_keys = ["adengine:impressions:#{day}", "adengine:impressions:badspot:#{day}", "adengine:impressions:biddablebuyerimpression:#{day}", "adengine:impressions:missingad:#{day}", "adengine:impressions:ownerimpression:#{day}", "adengine:impressions:missingurl:#{day}", "adengine:impressions:anonymous:#{day}", "adengine:impressions:missingbidsduetouser:#{day}", "adengine:impressions:missingduetohighcpm:#{day}"]

    [*1..10].each do |each_num|
      redis_keys << "adengine:impressions:BidForUserImpressionCount#{each_num}:#{day}"
    end

    redis_keys
  end
end
