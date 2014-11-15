class CookieMatch < ActiveRecord::Base


  scope :find_user, lambda {|plannto_user_id| where("plannto_user_id = '#{plannto_user_id}' and updated_at > '#{14.days.ago}'")}

  def self.check_cookie_user_exists?(plannto_user_id)
    matches = find_user(plannto_user_id)
    !matches.blank?
  end

  def self.enqueue_cookie_matching(param, plannto_user_id)
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => param["ref_url"]}
    Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
  end

  def self.process_cookie_matching(param)
    cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(param["plannto_user_id"])
    cookie_match.update_attributes(:google_user_id => param["google_gid"], :match_source => "google")

    $redis_rtb.pipelined do
      $redis_rtb.set("cm:#{param['google_gid']}", param["plannto_user_id"])
      $redis_rtb.expire("cm:#{param['google_gid']}", 2.weeks)
    end

    if !param["ref_url"].blank?
      user_access_detail = UserAccessDetail.create(:plannto_user_id => param["plan_to_temp_user_id"], :ref_url => param["ref_url"], :source => "google")
    end
  end
end
