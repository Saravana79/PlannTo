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
    if $redis.get("bulk_process_cookie_matching_is_running").to_i == 0
      $redis.set("bulk_process_cookie_matching_is_running", 1)
      $redis.expire("bulk_process_cookie_matching_is_running", 30.minutes)
      length = $redis.llen("resque:queue:cookie_matching_process")
      count = length

      source_categories = JSON.parse($redis.get("source_categories_pattern"))
      source_categories.default = {"pattern" => ""}

      begin
        cookie_details = $redis.lrange("resque:queue:cookie_matching_process", 0, 2000)
        cookies_arr = []
        user_access_details = []

        cookie_details.each do |cookie_detail|
          count -= 1
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
          p "Remaining CookieMatch Count - #{count}"
        end

        # ActiveRecord::Base.transaction do
        #   cookies_arr.each do |cookie_detail|
        #     cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookie_detail["plannto_user_id"])
        #     cookie_match.update_attributes(:google_user_id => cookie_detail["google_id"], :match_source => cookie_detail["source"])
        #   end
        # end

        imported_values = []
        cookies_arr.each do |cookie_detail|
          cookie_match = CookieMatch.new(:plannto_user_id => cookie_detail["plannto_user_id"], :google_user_id => cookie_detail["google_id"], :match_source => cookie_detail["source"])
          imported_values << cookie_match
        end

        result = CookieMatch.import(imported_values)

        result.failed_instances.each do |cookie_detail|
          cookie_match = CookieMatch.find_or_initialize_by_plannto_user_id(cookie_detail.plannto_user_id)
          cookie_match.update_attributes(:google_user_id => cookie_detail.google_user_id, :match_source => cookie_detail.match_source)
        end


        $redis_rtb.pipelined do
          cookies_arr.each do |cookie_detail|
            $redis_rtb.set("cm:#{cookie_detail['google_id']}", cookie_detail["plannto_user_id"])
            $redis_rtb.expire("cm:#{cookie_detail['google_id']}", 2.weeks)
          end
        end

        user_access_details_count = user_access_details.count
        user_access_details_import = []
        user_access_details.each do |user_access_detail|
          user_access_details_count-=1
          new_user_access_detail = UserAccessDetail.new(:plannto_user_id => user_access_detail["plannto_user_id"], :ref_url => user_access_detail["ref_url"], :source => user_access_detail["source"])
          user_access_details_import << new_user_access_detail
          #user_access_detail.update_buying_list_in_redis(source_categories)

          article_content = ArticleContent.find_by_sql("select sub_type,group_concat(icc.item_id) all_item_ids, ac.id from article_contents ac inner join contents c on ac.id = c.id
inner join item_contents_relations_cache icc on icc.content_id = ac.id
where url = '#{new_user_access_detail.ref_url}' group by ac.id").last

          unless article_content.blank?
            user_id = new_user_access_detail.plannto_user_id
            type = article_content.sub_type
            item_ids = article_content.all_item_ids.to_s rescue ""
            UserAccessDetail.update_buying_list(user_id, new_user_access_detail.ref_url, type, item_ids, source_categories)
          end
          p "Remaining UserAccessDetail Count - #{user_access_details_count}"
        end

        UserAccessDetail.import(user_access_details_import)

        $redis.ltrim("resque:queue:cookie_matching_process", cookie_details.count, -1)
        length = length - cookie_details.count
        p "*********************************** Remaining CookieMatch Length - #{length} **********************************"
      end while length > 0
      $redis.set("bulk_process_cookie_matching_is_running", 0)
    end
  end

end