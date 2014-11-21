class Advertisement < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :click_url
  has_attached_file :upload_image,
                    :styles => {:medium => "120x120>", :thumb => "24x24>"},
                    :storage => :s3,
                    :bucket => ENV['planntonew'],
                    :s3_credentials => "config/s3.yml",
                    :path => "images/advertisements/:id/:style/:filename",
                    :url => ":s3_sg_url"

  has_many :images, as: :imageable, :dependent => :destroy
  has_many :add_impressions
  has_many :order_histories
  belongs_to :content
  belongs_to :user
  belongs_to :vendor
  has_one :ad_video_detail
  has_many :aggregated_details, :as => :entity
  has_many :ad_reports

  after_create :item_update_with_created_ad_item_ids
  after_save :update_click_url_based_on_vendor
  after_save :update_redis_with_advertisement

  scope :get_ad_by_id, lambda { |id| where("id = ?", id) }

  STATUS = ["","valid"]

  HOURS = [*0..23]

  #validate :file_dimensions

  def self.url_params_process(param)
    url_params = "Params = "
    param = param.reject { |s| ["controller", "action"].include?(s) }
    keys = param.keys
    values = param.values

    [*0...keys.count].each do |each_val|
      url_params = url_params + "#{keys[each_val]}-#{values[each_val]};"
    end
    return url_params
  end

  def self.process_size(width, height=0)
    width = width.to_i
    height = height.to_i
    if (width <= 120)
      return_val = "120"
    elsif (width <= 130)
      return_val = "127"
    elsif (width < 350 && height == 600)
      return_val = "300_600"
    elsif (width < 350)
      return_val = "300"
    elsif (width < 500)
      return_val = "468"
    elsif (width < 750)
      return_val = "728"
    else
      return_val = "120"
    end
    return return_val
  end

  def build_images(image_array, ad_type=nil)
    image_array.each do |image|
      p image
      new_image = self.images.build
      new_image.avatar = image[:avatar]
      new_image.ad_size = image[:ad_size]
      if ad_type != "flash" && Image.file_dimensions(new_image)
        new_image.save
      else
        new_image.save
      end
    end
  end

  def self.calculate_ecpm
    advertisements = Advertisement.where("bid = 'CPC'")
    count = 0
    advertisements.each do |advertisement|
      clicks_count = Click.joins(:add_impression).where("add_impressions.advertisement_id = ?", advertisement.id).count
      impressions_count = advertisement.add_impressions.count

      if (clicks_count != 0 && impressions_count != 0)
        count = count + 1
        ecpm = (clicks_count/impressions_count) * 1000 * advertisement.cost
        if (advertisement.ecpm.to_i > 0)
          advertisement.update_attributes(:ecpm => ecpm) if (ecpm.to_i > 0)
        else
          advertisement.update_attributes(:ecpm => ecpm)
        end
      end
    end
    return count
  end

  def update_click_url_based_on_vendor
    if !self.vendor.blank? && self.advertisement_type == "dynamic"
      vendor = self.vendor
      vendor_detail = vendor.vendor_details.first
      click_url = vendor_detail.baseurl
      self.update_column('click_url', click_url)
    end
  end

  def update_redis_with_advertisement
    #$redis.HMSET("advertisments:#{id}", "type", type, "vendor_id", vendor_id, "ecpm", ecpm, "dailybudget", dailybudget)

    formatted_click_url = Advertisement.make_valid_url(click_url)

    ad_status = "disabled"
    if status.to_i == 1
      if ((!start_date.blank? && start_date.to_date <= Date.today) && (!end_date.blank? && end_date.to_date >= Date.today))
        ad_status = "enabled"
      end

      if budget_changed?
        hour = Time.now.hour
        new_budget = get_hourly_budget(0)
        $redis.set("ad:spent:#{id}", new_budget*1000000)
      end
    end

    supported_sizes = self.images.map(&:ad_size).uniq.join(",")

    Resque.enqueue(UpdateRedis, "advertisments:#{id}", "type", advertisement_type, "vendor_id", vendor_id, "ecpm", ecpm.to_i, "dailybudget", budget, "click_url", formatted_click_url, "status", ad_status, "exclusive_item_ids", exclusive_item_ids, "excluded_sites", excluded_sites, "supported_sizes", supported_sizes)

    # Enqueue ItemUpdate with created advertisement item_ids
    # item_ids_array = self.content.blank? ? [] : self.content.allitems.map(&:id)
    # item_ids = item_ids_array.map(&:inspect).join(',')
    # Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
  end

  def item_update_with_created_ad_item_ids
    item_ids_array = self.content.blank? ? [] : self.content.allitems.map(&:id)
    item_ids = item_ids_array.map(&:inspect).join(',')
    Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
  end

  def self.make_valid_url(click_url)
    click_url = click_url.to_s
    if click_url.include?("www.")
      exp = click_url.split("www.")
      click_url = "http://www." + exp[1].to_s
    elsif click_url.include?("http://")
      exp = click_url.split("http://")
      click_url = "http://www." + exp[1].to_s
    else
      click_url = click_url.blank? ? "" : "http://www." + click_url
    end
  end

  def self.update_rtb_budget(log, actual_time)
    date = actual_time.to_date
    advertisements = find_by_start_and_end_date(date)
    advertisements.each do |advertisement|
      account_name = "PlannToAccount_#{advertisement.id}"
      actual_time = actual_time.to_time
      hour = actual_time.hour
      log.debug "time - #{actual_time}, hour - #{hour}"
      p "time - #{actual_time}, hour - #{hour}"

      if (configatron.rtb_budget_reset_time == hour)
        release_unspent_rtb_budget(account_name)
      end

      url = "#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}"
      # uri = URI(url)
      # account = Net::HTTP.get(uri)
      account = RestClient.get(url) rescue "\"couldn't get account\"\n"

      if account == "\"couldn't get account\"\n"
        create_url = "#{configatron.rtbkit_hostname}/v1/accounts?accountName=#{account_name}&accountType=budget"
        # uri_to_create = URI(create_url)
        # response = Net::HTTP.post_form(uri_to_create, {})

        begin
          response = RestClient.post create_url, :content_type => :json, :accept => :json
        rescue Exception => e
          raise "#{advertisement.id} - #{e.response}"
        end
        puts "Response #{response.code}: Created New Account #{account_name}"
        account = response.body
      end

      hourly_budget = advertisement.get_hourly_budget(hour)

      effective_budget = get_effective_budget_using_summary(account_name)
      if (hourly_budget != 0 && !effective_budget.blank?)
        current_budget = effective_budget + configatron.rtb_initial_budget
        budget_now = current_budget + (hourly_budget * 1000000)
        payload = {"USD/1M" => budget_now}.to_json
        post_budget(account_name, payload)
      end
    end
  end

  def self.update_ad_1_budget_per_hour
    account_name = "PlannToAccount_1"

    # effective_budget = get_effective_budget_using_summary(account_name)
    budget_now = 5000 * 1000000
    payload = {"USD/1M" => budget_now}.to_json
    post_budget(account_name, payload)
  end

  def self.find_by_start_and_end_date(date)
    Advertisement.where("status = ? and start_date <= ? and end_date >= ?", 1, date, date)
  end

  def get_hourly_budget(hour)
    scheduled_valid_hours = self.schedule_details.to_s.split(",")
    valid_hours = scheduled_valid_hours.blank? ? HOURS : scheduled_valid_hours.map(&:to_i)
    if valid_hours.include?(hour)
      hourly_budget = self.budget.to_f / valid_hours.count
    else
      hourly_budget = 0
    end
    hourly_budget
  end

  def self.release_unspent_rtb_budget(account_name)
    summary_url = "#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}/summary"
    account = RestClient.get summary_url
    account_hash = JSON.parse(account)
    inflight = account_hash["inFlight"]["USD/1M"].to_i

    payload = { "USD/1M" => configatron.rtb_initial_budget + inflight }.to_json
    post_budget(account_name, payload)
  end

  def self.get_effective_budget_using_summary(account_name)
    summary_url = "#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}/summary"
    # uri = URI(summary_url)
    # account = Net::HTTP.get(uri)

    account = RestClient.get summary_url
    effective_budget = nil

    if account != "\"couldn't get account\"\n"
      account_hash = JSON.parse(account)
      effective_budget = account_hash["account"]["budgetIncreases"]["USD/1M"].to_i - account_hash["account"]["budgetDecreases"]["USD/1M"].to_i + account_hash["account"]["recycledIn"]["USD/1M"].to_i - account_hash["account"]["recycledOut"]["USD/1M"].to_i + account_hash["account"]["allocatedIn"]["USD/1M"].to_i - account_hash["account"]["allocatedOut"]["USD/1M"].to_i
      # total_budget = account_hash["budget"]["USD/1M"]
    end
    return effective_budget
  end

  def self.post_budget(account_name, payload)
    url_budget = "#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}/budget"
    # uri_post = URI(url_budget)
    # req = Net::HTTP::Post.new(uri_post.path, initheader = {'Content-Type' => 'application/json'})
    # req.body = payload
    # response = Net::HTTP.new(uri_post.host, uri_post.port).start { |http| http.request(req) }

    begin
      response = RestClient.post url_budget, payload, :content_type => :json, :accept => :json
    rescue Exception => e
      raise "#{account_name} - #{e.response}"
    end

    puts "Response #{response.code}"
  end

  def self.create_impression_before_cache(param, request_referer, url_params, plan_to_temp_user_id, user_id, remote_ip, impression_type, item_ids, ads_id, advertisement=false)
    param = param.symbolize_keys
    param[:is_test] ||= 'false'
    param[:more_vendors] ||= "false"
    param[:ref_url] ||= ""
    url, itemsaccess = assign_url_and_item_access(param[:ref_url], request_referer)

    @publisher = Publisher.getpublisherfromdomain(url)

    if advertisement != true
      if !@publisher.blank? && @publisher.id == 9
        itemsaccess = "othercountry"
      elsif param[:show_price] != "false"
        itemsaccess = itemsaccess
      else
        itemsaccess = "offers"
      end
    end

    if param[:is_test] != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids, url, user_id, remote_ip, nil, itemsaccess, url_params,
                                                              plan_to_temp_user_id, ads_id, param[:wp], param[:sid])
      Advertisement.check_and_update_act_spent_budget_in_redis(ads_id,param[:wp])
    end
    return @impression_id
  end

  def self.make_url_params(param)
    url_params = "Params = "
    param = param.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_"].include?(s.to_s)}
    keys = param.keys
    values = param.values

    [*0...keys.count].each do |each_val|
      url_params = url_params + "#{keys[each_val].to_s}-#{values[each_val].to_s};"
    end

    url_params
  end

  def self.make_url_params_for_cookie_matching(param)
    url_params = "Params = "
    param = param.reject {|s| ["controller", "action", "google_gid", "ref_url", "source"].include?(s.to_s)}
    keys = param.keys
    values = param.values

    [*0...keys.count].each do |each_val|
      url_params = url_params + "#{keys[each_val].to_s}-#{values[each_val].to_s};"
    end

    url_params
  end

  def self.assign_url_and_item_access(ref_url, request_referer)
    if (ref_url && ref_url != "" && ref_url != 'undefined')
      return ref_url, "ref_url"
    else
      return request_referer, "referer"
    end
  end

  def self.get_extra_details(advertisements, date, user)
    start_date, end_date = date.to_s.split("/")
    extra_details = {}
    advertisements.each do |each_ad|
      if end_date.blank?
        query = "SELECT `aggregated_details`.* FROM `aggregated_details` WHERE (entity_type = 'advertisement' and entity_id = #{each_ad.id} and date = '#{start_date}')"
      else
        query = "select sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count, sum(winning_price) as winning_price from aggregated_details WHERE (entity_type = 'advertisement' and entity_id = #{each_ad.id} and date >= '#{start_date}' and date <= '#{end_date}')"
      end
      aggrgated_detail = AggregatedDetail.find_by_sql(query).first
      aggrgated_detail = AggregatedDetail.new if aggrgated_detail.blank?
      ctr = 0.0
      if (aggrgated_detail.clicks_count.to_f != 0.0 && aggrgated_detail.impressions_count.to_f != 0.0)
        ctr = (aggrgated_detail.clicks_count.to_f / aggrgated_detail.impressions_count.to_f) * 100 rescue 0.0
      end

      winning_price = aggrgated_detail.winning_price.to_f.round(2)

      if user.is_admin?
        date_condition = "order_date >= '#{start_date}'"
        date_condition = date_condition + " and order_date <= '#{end_date}'" unless end_date.blank?

        query_for_get_revenue = "select sum(total_revenue) revenue from order_histories where advertisement_id = #{each_ad.id} and #{date_condition}"
        order_history = OrderHistory.find_by_sql(query_for_get_revenue).first
        total_revenue = order_history.revenue.to_f
      else
        total_revenue = 0
      end

      extra_details.merge!("#{each_ad.id}" => {"impressions" => aggrgated_detail.impressions_count, "clicks" => aggrgated_detail.clicks_count, "cost" => winning_price, "ctr" => "#{ctr.round(2)} %", "revenue" => total_revenue})
    end
    extra_details
  end

  def self.check_and_update_act_spent_budget_in_redis(advertisement_id, winning_price_enc)
    if !advertisement_id.blank? && !winning_price_enc.blank?
      time = Time.now
      winning_price = AddImpression.get_winning_price_value(winning_price_enc).to_i
      act_spent_key = "ad:act_hourly_spent:#{time.strftime("%b-%d")}:#{advertisement_id}:#{time.hour}"

      return_val,hourly_spent = $redis.pipelined do
        $redis.incrby(act_spent_key, winning_price)
        $redis.get("ad:spent:#{advertisement_id}")
      end

      if return_val >= hourly_spent.to_i
        $redis_rtb.hset("advertisments:#{advertisement_id}", "status", "paused")
        time_usage = (time.min.to_f/60)*100
        param = {"advertisement_id" => advertisement_id, "spent_date" => time.to_date, "hour" => time.hour, "time_usage" => time_usage}
        Resque.enqueue(AdHourlySpentDetailProcess, "create_ad_houly_spent_detail", param)
      end
    end
  end

  def self.check_and_update_hourly_budget
    time = Time.zone.now + 10.minutes
    hour = time.hour
    advertisements = Advertisement.where(:status => 1)
    
    # if INVALID_HOURS.include?(hour)
    #   advertisements.each do |advertisement|
    #     $redis_rtb.hset("advertisments:#{advertisement.id}", "status", "paused")
    #     old_hour = hour-1
    #     return if INVALID_HOURS.include?(old_hour)
    #     update_remaining_budget_to_spent(advertisement.id, time)
    #   end
    #   return
    # end

    advertisements.each do |advertisement|
      scheduled_valid_hours = advertisement.schedule_details.to_s.split(",")
      valid_hours = scheduled_valid_hours.blank? ? HOURS : scheduled_valid_hours.map(&:to_i)
      invalid_hours = HOURS - valid_hours
      if invalid_hours.include?(hour)
        $redis_rtb.hset("advertisments:#{advertisement.id}", "status", "paused")
        advertisement
        # AdHourlySpentDetail.create(:advertisement_id => advertisement.id, :spent_date => time.to_date, :hour => hour, :time_usage => 0, :price_usage => 0)
        # old_hour = hour-1
        # next if invalid_hours.include?(old_hour)
        # update_remaining_budget_to_spent(advertisement.id, time, valid_hours)
      end
    end

    if hour == 0
      advertisements.each do |advertisement|
        key = "ad:spent:#{advertisement.id}"
        spent = advertisement.get_hourly_budget(0).to_i
        $redis.set(key, spent*1000000)
        $redis_rtb.hset("advertisments:#{advertisement.id}", "status", "enabled")
      end
    else
      advertisements.each do |advertisement|
        scheduled_valid_hours = advertisement.schedule_details.to_s.split(",")
        valid_hours = scheduled_valid_hours.blank? ? HOURS : scheduled_valid_hours.map(&:to_i)
        # invalid_hours = HOURS - valid_hours

        if valid_hours.include?(hour)
          $redis_rtb.hset("advertisments:#{advertisement.id}", "status", "enabled")
          # old_hour = hour-1
          # next if invalid_hours.include?(old_hour)
          update_remaining_budget_to_spent(advertisement.id, time, valid_hours)
        end
      end
    end
  end

  def self.update_remaining_budget_to_spent(advertisement_id, time, valid_hours)
    hour = time.hour
    prev_valid_hour = valid_hours.select {|a| a < hour}.max

    if !prev_valid_hour.blank?
      prev_spent_key = "ad:act_hourly_spent:#{time.strftime("%b-%d")}:#{advertisement_id}:#{prev_valid_hour}"
      prev_spent = $redis.get(prev_spent_key).to_i
      spent = $redis.get("ad:spent:#{advertisement_id}").to_i

      # create ad hourly spent detail
      price_usage = (prev_spent.to_f/spent)*100
      ad_hourly_spent_detail = AdHourlySpentDetail.find_or_initialize_by_advertisement_id_and_spent_date_and_hour(advertisement_id, time.to_date, hour)
      time_usage = ad_hourly_spent_detail.time_usage.to_i == 0 ? 100 : ad_hourly_spent_detail.time_usage
      ad_hourly_spent_detail.update_attributes(:time_usage => time_usage, :price_usage => price_usage)

      if prev_spent < spent
        remaining_amt = spent - prev_spent
        v_hours = valid_hours.each {|each_val| each_val >= hour}
        val_for_add = (remaining_amt/v_hours.count).to_i
        $redis.set("ad:spent:#{advertisement_id}", spent+val_for_add)
      end
    end
  end

  def self.generate_report_for_ads(ad_report_id)
    ad_report = AdReport.where(:id => ad_report_id).first

    impression_date_condition = "impression_time > '#{ad_report.from_date.beginning_of_day.strftime('%F %T')}' and impression_time < '#{ad_report.to_date.end_of_day.strftime('%F %T')}'"
    click_date_condition = "timestamp > '#{ad_report.from_date.beginning_of_day.strftime('%F %T')}' and timestamp < '#{ad_report.to_date.end_of_day.strftime('%F %T')}'"

    if ad_report.report_type == "item_id"
      query = "select a.item_id,i.name,impressions_count,clicks_count from (select  ai.item_id, count(*) as impressions_count from add_impressions ai
               where advertisement_id = #{ad_report.advertisement_id} and #{impression_date_condition} group by item_id ) a left outer join (select item_id, count(*) as clicks_count from
               clicks where advertisement_id = #{ad_report.advertisement_id} and #{click_date_condition} group by item_id ) b on a.item_id= b.item_id inner join items i on i.id = a.item_id
               order by impressions_count desc"
    else
      query = "select a.hosted_site_url,impressions_count,clicks_count from (select  ai.hosted_site_url, count(*) as impressions_count from add_impressions ai
               where advertisement_id = #{ad_report.advertisement_id} and #{impression_date_condition} group by hosted_site_url ) a left outer join (select hosted_site_url, count(*) as
               clicks_count from clicks where advertisement_id = #{ad_report.advertisement_id} and #{click_date_condition} group by hosted_site_url ) b on a.hosted_site_url= b.hosted_site_url
               order by impressions_count desc"
    end

    reports = Advertisement.find_by_sql(query)

    return_val = CSV.generate do |csv|
      csv << [ad_report.report_type == "item_id" ? "Item Name" : "Hosted Site Url", "Impressions Count", "Clicks Count", "ectr"]
      reports.each do |report|
        ectr = ((report.clicks_count.to_f/report.impressions_count.to_f)*100).round(3)
        csv << [*report.send(ad_report.report_type == "item_id" ? "name" : "hosted_site_url"), report.impressions_count, report.clicks_count, ectr]
      end
    end

    filename = ad_report.filename

    object = $s3_object.objects["reports/#{filename}"]
    object.write(return_val)
    object.acl = :public_read

    ad_report.update_attributes(:status => "ready")
  end

  def self.to_csv(param, reports)
    CSV.generate do |csv|
      csv << [param[:select_by] == "item_id" ? "Item Name" : "Hosted Site Url", "Impressions Count", "Clicks Count", "ectr"]
      reports.each do |report|
        csv << [*report.send(param[:select_by] == "item_id" ? "name" : "hosted_site_url"), report.impressions_count, report.clicks_count, report.ectr.to_f.round(4)]
      end
    end
  end

  def my_reports(user)
    ad_reports.where(:reported_by => user.id).order("created_at desc")
  end

  def self.bulk_process_impression_and_click()
    if $redis.get("bulk_process_add_impression_is_running").to_i == 0
      $redis.set("bulk_process_add_impression_is_running", 1)
      $redis.expire("bulk_process_add_impression_is_running", 20.minutes)
      length = $redis.llen("resque:queue:create_impression_and_click")
      count = length

      begin
        add_impressions = $redis.lrange("resque:queue:create_impression_and_click", 0, 500)
        cookies_arr = []
        user_access_details = []

        add_impressions.each do |each_rec|
          count -= 1
          begin
            each_rec_arr = JSON.parse(each_rec)["args"]
            each_rec_class = each_rec_arr[0]
            each_rec_detail = each_rec_arr[1]

            if each_rec_class == "AddImpression"
              AddImpression.create_new_record(each_rec_detail)
            elsif each_rec_class == "Click"
              Click.create_new_record(each_rec_detail)
            elsif each_rec_class == "VideoImpression"
              VideoImpression.create_new_record(each_rec_detail)
            end
          rescue Exception => e
            p "There was problem while running impressions process => #{e.backtrace}"
          end
          p "Remaining click_or_impressions Count - #{count}"
        end

        # UserAccessDetail.create(user_access_details)

        $redis.ltrim("resque:queue:create_impression_and_click", add_impressions.count, -1)
        length = length - add_impressions.count
        p "*********************************** Remaining CookieMatch Length - #{length} **********************************"
      end while length > 0
      $redis.set("bulk_process_add_impression_is_running", 0)
      Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc, "true")
    end
  end

  private

  def file_dimensions
    hieght_width = self.ad_size.split("x")
    dimensions = Paperclip::Geometry.from_file(upload_image.queued_for_write[:original].path)
    logger.info "===========================================#{dimensions.width} +++++++++++++++#{dimensions.height}"
    if dimensions.width.to_i.to_s != hieght_width[0] || dimensions.height.to_i.to_s != hieght_width[1]
      errors.add :file, "Width must be #{hieght_width[0]}px and height must be #{hieght_width[1]}px"
    end
  end

end
