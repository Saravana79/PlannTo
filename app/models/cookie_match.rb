class CookieMatch < ActiveRecord::Base
  validates_uniqueness_of :plannto_user_id

  scope :find_user, lambda {|plannto_user_id| where("plannto_user_id = '#{plannto_user_id}' and updated_at > '#{14.days.ago}'")}

  def self.check_cookie_user_exists?(plannto_user_id)
    matches = find_user(plannto_user_id)
    !matches.blank?
  end

  def self.enqueue_cookie_matching(param, plannto_user_id)
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => param["ref_url"], "source" => "google"}
    Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
  end

  def self.enqueue_pixel_matching(param, plannto_user_id)
    valid_param = {"google_id" => param["google_gid"], "plannto_user_id" => plannto_user_id, "ref_url" => "", "source" => "google_pixel"}
    Resque.enqueue(CookieMatchingProcess, "process_cookie_matching", valid_param)
  end

  def self.process_cookie_matching(param)
    param["source"] ||= "google"
    cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(param["plannto_user_id"])
    cookie_match.update_attributes(:google_user_id => param["google_id"], :match_source => param["source"])

    $redis_rtb.pipelined do
      $redis_rtb.set("cm:#{param['google_id']}", param["plannto_user_id"])
      $redis_rtb.expire("cm:#{param['google_id']}", 2.weeks)
    end

    if !param["ref_url"].blank?
      user_access_detail = UserAccessDetail.create(:plannto_user_id => param["plannto_user_id"], :ref_url => param["ref_url"], :source => param["source"])
    end
  end

  def self.bulk_process_cookie_matching()
    length = $redis.llen("resque:queue:cookie_matching_process")

    source_categories = JSON.parse($redis.get("source_categories_pattern"))
    source_categories.default = {"pattern" => ""}

    begin
      cookie_details = $redis.lrange("resque:queue:cookie_matching_process", 0, 1000)
      cookies_arr = []
      user_access_details = []

      cookie_details.each do |cookie_detail|
        begin
          cookie_detail = JSON.parse(cookie_detail)["args"][1]
          cookie_detail["source"] ||= "google"
          ref_url = cookie_detail.delete("ref_url")
          cookies_arr << cookie_detail
          if !ref_url.blank?
            param = {"plannto_user_id" => cookie_detail["plannto_user_id"], "ref_url" => ref_url, "source" => cookie_detail["source"]}
            user_access_details << param
          end
        rescue Exception => e
          p "There was problem while running cookie_match => #{e.backtrace}"
        end
      end

      ActiveRecord::Base.transaction do
        cookies_arr.each do |cookie_detail|
          cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookie_detail["plannto_user_id"])
          cookie_match.update_attributes(:google_user_id => cookie_detail["google_id"], :match_source => cookie_detail["source"])
        end
      end

      cookies_arr.each do |cookie_detail|
        $redis_rtb.pipelined do
          $redis_rtb.set("cm:#{cookie_detail['google_id']}", cookie_detail["plannto_user_id"])
          $redis_rtb.expire("cm:#{cookie_detail['google_id']}", 2.weeks)
        end
      end

      UserAccessDetail.create(user_access_details)

      $redis.ltrim("resque:queue:cookie_matching_process", cookie_details.count, -1)
      length = length - cookie_details.count
      p "Remaining CookieMatch Length - #{length}"
    end while length > 0
  end

end