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
  has_many :clicks
  has_many :order_histories
  belongs_to :content
  belongs_to :user
  belongs_to :vendor
  has_one :ad_video_detail
  has_one :adv_detail
  has_many :aggregated_details, :as => :entity
  has_many :user_relationships, :as => :relationship
  has_many :ad_reports

  before_save :convert_device_to_string

  after_create :item_update_with_created_ad_item_ids
  after_save :update_click_url_based_on_vendor
  after_save :update_redis_with_advertisement
  after_save :update_user_relationship

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
    if (width == 336 && height == 280)
      return_val = "336_280"
    elsif (width == 250 && height == 250)
      return_val = "250_250"
    elsif (width == 200 && height == 200)
      return_val = "200_200"
    elsif (width == 160 && height == 600)
      return_val = "160_600"
    elsif (width == 320 && height == 50)
      return_val = "320_50"
    elsif (width == 320 && height == 100)
      return_val = "320_100"
    elsif (width <= 120)
      return_val = "120"
    elsif (width <= 130)
      return_val = "127"
    elsif (width < 350 && height == 600)
      return_val = "300_600"
    elsif (width < 350 && height == 60)
      return_val = "300_60"
    elsif (width < 350)
      return_val = "300"
    elsif (width < 500)
      return_val = "468"
    elsif (width < 750)
      return_val = "728"
     elsif (width < 972)
      return_val = "970"   
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
      if !["flash", "in_image_ads"].include?(ad_type) && Image.file_dimensions(new_image)
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
      clicks_count = Click.joins(:add_impression).where("add_impressions1.advertisement_id = ?", advertisement.id).count
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
      # vendor = self.vendor
      vendor_detail = self.vendor_detail
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

    ad_video_detail = self.ad_video_detail

    if !ad_video_detail.blank?
      total_time = ad_video_detail.total_time
      total_time = total_time.to_s.split(":")[2].to_i
      total_time = total_time * 1000
      skip = ad_video_detail.skip

      Resque.enqueue(UpdateRedis, "advertisments:#{id}", "type", advertisement_type, "vendor_id", vendor_id, "ecpm", ecpm.to_i, "dailybudget", budget, "click_url", formatted_click_url, "status", ad_status, "exclusive_item_ids", exclusive_item_ids.to_s + man_exclusive_item_ids.to_s, "excluded_sites", excluded_sites, "supported_sizes", supported_sizes, "skip", skip, "total_time", total_time)
    else
      Resque.enqueue(UpdateRedis, "advertisments:#{id}", "type", advertisement_type, "vendor_id", vendor_id, "ecpm", ecpm.to_i, "dailybudget", budget, "click_url", formatted_click_url, "status", ad_status, "exclusive_item_ids", exclusive_item_ids.to_s + man_exclusive_item_ids.to_s, "excluded_sites", excluded_sites, "supported_sizes", supported_sizes)
    end

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
    if click_url.include?("http://") || click_url.include?("https://")
      click_url = click_url
    elsif !click_url.blank?
      click_url = "http://" + click_url
    else
      click_url = ""
    end
  end

  def self.update_rtb_budget(log, actual_time)
    date = actual_time.to_date
    advertisements = Advertisement.find_by_start_and_end_date(date)
    advertisements.each do |advertisement|
      account_name = "PlannToAccount_#{advertisement.id}"
      actual_time = actual_time.to_time
      hour = actual_time.hour
      log.debug "time - #{actual_time}, hour - #{hour}"
      p "time - #{actual_time}, hour - #{hour}"

      if (configatron.rtb_budget_reset_time == hour)
        Advertisement.release_unspent_rtb_budget(account_name)
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
          # raise "#{advertisement.id} - #{e.response}"
          p "#{advertisement.id} - #{e.response}"
          puts "Response #{response.code}: Created New Account #{account_name}"
          next
        end
        # account = response.body
      end

      hourly_budget = advertisement.get_hourly_budget(hour)

      effective_budget = get_effective_budget_using_summary(account_name)
      if (hourly_budget != 0 && !effective_budget.blank?)
        current_budget = effective_budget + configatron.rtb_initial_budget
        budget_now = current_budget + (hourly_budget * 1000000)
        payload = {"USD/1M" => budget_now}.to_json
        Advertisement.post_budget(account_name, payload)
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
    # param = param.symbolize_keys
    param["is_test"] ||= 'false'
    param["more_vendors"] ||= "false"
    param["ref_url"] ||= ""
    url, itemsaccess = assign_url_and_item_access(param["ref_url"], request_referer)

    # if advertisement != true
    #   @publisher = Publisher.getpublisherfromdomain(url)
    #   if !@publisher.blank? && @publisher.id == 9
    #     itemsaccess = "othercountry"
    #   elsif param[:show_price] != "false"
    #     itemsaccess = itemsaccess
    #   else
    #     itemsaccess = "offers"
    #   end
    # end

    if param["is_test"] != "true"
      @impression_id = AddImpression.add_impression_to_resque(impression_type, item_ids, url, user_id, remote_ip, nil, itemsaccess, url_params,
                                                              plan_to_temp_user_id, ads_id, param["wp"], param["sid"], param["t"], param["r"], param["a"], param["video"], param["video_impression_id"], param["visited"])
      Advertisement.check_and_update_act_spent_budget_in_redis(ads_id,param["wp"])
    end
    return @impression_id
  end

  def self.make_url_params(param)
    url_params = "Params = "
    param = param.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_", "click_url", "hou_dynamic_l", "protocol_type", "price_full_details", "doc_title-undefined", "wp"].include?(s.to_s)}
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

  def self.reverse_make_url_params(url_params)
    url_params = url_params.to_s.gsub("Params = ", "")

    new_array = []

    url_params = url_params.split(";")
    # url_params.each {|each_pair| new_array << each_pair.split("-")}
    url_params.each do |each_pair|
      hash_val = each_pair.split("-")
      if hash_val.count == 2
        new_array << hash_val
      else
        hash_key = hash_val[0]
        hash_val = hash_val - [hash_key]
        hash_val = hash_val.join("-")
        new_array << [hash_key, hash_val]
      end
    end

    param_hash = Hash[new_array]
    param_hash
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

  if(user.id == 335)
      start_date = "18-12-2014".to_date
      end_date = "20-12-2014".to_date
    end

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

      $redis.expire(act_spent_key, 2.hours)

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

    impression_date_condition = "impression_time > '#{ad_report.from_date.beginning_of_day.utc.strftime('%F %T')}' and impression_time < '#{ad_report.to_date.end_of_day.utc.strftime('%F %T')}'"
    click_date_condition = "timestamp > '#{ad_report.from_date.beginning_of_day.utc.strftime('%F %T')}' and timestamp < '#{ad_report.to_date.end_of_day.utc.strftime('%F %T')}'"

    if ad_report.report_type == "item_id"
      query = "select a.item_id,i.name,impressions_count,clicks_count from (select  ai.item_id, count(*) as impressions_count from add_impressions1 ai
               where advertisement_id = #{ad_report.advertisement_id} and #{impression_date_condition} group by item_id ) a left outer join (select item_id, count(*) as clicks_count from
               clicks where advertisement_id = #{ad_report.advertisement_id} and #{click_date_condition} group by item_id ) b on a.item_id= b.item_id inner join items i on i.id = a.item_id
               order by impressions_count desc"
    else
      query = "select a.hosted_site_url,impressions_count,clicks_count from (select  ai.hosted_site_url, count(*) as impressions_count from add_impressions1 ai
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

  def self.generate_more_reports_direct(param)
    param[:ad_id] = param[:id]
    param[:report_sort_by] = "imp_count"
    param[:ad_type] = "advertisement"
    param[:show_downloads] ||= "false"
    param[:sort_by] ||= "total_imp"

    start_date = param[:from_date].blank? ? Date.today.beginning_of_day : param[:from_date].to_date.beginning_of_day
    end_date = param[:to_date].blank? ? Date.today.end_of_day : param[:to_date].to_date.end_of_day

    @results = AggregatedImpression.get_results_from_agg_impression(param, start_date, end_date)
  end

  def self.generate_more_reports(ad_report_id)
    ad_report = AdReport.where(:id => ad_report_id).first

    param = ad_report.attributes.symbolize_keys.slice(*[:from_date, :to_date, :ad_type])
    param[:type] = ad_report.report_type
    param[:ad_id] = ad_report.ad_ids
    param[:report_sort_by] = "imp_count"

    start_date = ad_report.from_date.blank? ? Date.today.beginning_of_day : ad_report.from_date.to_date.beginning_of_day
    end_date = ad_report.to_date.blank? ? Date.today.end_of_day : ad_report.to_date.to_date.end_of_day
    # advertisements = ["All"] + Advertisement.all.map(&:id)
    results = AdImpression.get_results_from_mongo(param, start_date, end_date)

    return_val = CSV.generate do |csv|
      csv << ["#{ad_report.report_type}", "Total Impressions", "Total Clicks", "CTR", "Cost", "Total Orders", "Total Revenue"]
      results.each do |report|
        item_ids = results.map {|each_row| each_row["_id"]}.compact.map(&:to_i)
        items = Item.where(:id => item_ids)
        if ad_report.report_type == "Item"
          item = items.select {|item| item.id == report["_id"].to_i}.last
          item_id = item.blank? ? report["_id"].to_s : item.name.to_s
        else
          item_id = report["_id"].to_i
        end

        ectr = ((report["click_count"].to_f/report["imp_count"].to_f)*100).round(2).to_s + " %"

        p [*item_id, report["imp_count"], report["click_count"], ectr, report["winning_price"], report["orders_count"], report["orders_sum"].flatten.compact.sum]
        csv << [*item_id, report["imp_count"], report["click_count"], ectr, report["winning_price"], report["orders_count"], report["orders_sum"].flatten.compact.sum]
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
      mins = $redis.llen("resque:queue:create_impression_and_click").to_i / 1000 rescue 30
      $redis.expire("bulk_process_add_impression_is_running", mins.minutes)
      length = $redis.llen("resque:queue:create_impression_and_click")
      count = length

      # $redis.set("valid_item_types_for_buying_list", "Car,Bike") #Note to set item types
      valid_item_types = $redis.get("valid_item_types_for_buying_list").to_s.split(",")
      #$redis.set("valid_item_ids_for_buying_list", "28712,75427,73319") #Note to set item ids
      valid_item_ids = $redis.get("valid_item_ids_for_buying_list").to_s.split(",")
      # $redis.set("valid_ad_ids_for_buying_list", "1,25") #Note to set ad ids
      valid_ad_ids = $redis.get("valid_ad_ids_for_buying_list").to_s.split(",")

      valid_item_ids_from_ads = $redis.get("valid_item_ids_from_ads_for_buying_list").to_s.split(",")

      if valid_item_ids_from_ads.blank?
        valid_item_ids_from_ads = Advertisement.get_valid_item_ids_from_ads(valid_ad_ids)

        $redis.set("valid_item_ids_from_ads_for_buying_list", valid_item_ids_from_ads.join(","))
        $redis.expire("valid_item_ids_from_ads_for_buying_list", 24.hours)
      end

      valid_item_ids = (valid_item_ids_from_ads + valid_item_ids).flatten.uniq

      error_count = 0
      begin
        add_impressions = $redis.lrange("resque:queue:create_impression_and_click", 0, 1000)

        impression_import = []
        impression_import_mongo = []
        video_comp_impression_import_mongo = []
        ad_impressions_list = []
        clicks_import = []
        clicks_import_mongo = []
        video_imp_import = []
        non_ad_impressions_list = []
        update_impressions = []
        ads_hash = {}
        publisher_hash = {}
        items_hash = {}
        domains_hash = {}
        sid_hash = {}

        ads = Advertisement.select("id,commission")
        ad_detail_hash = {}

        ads.each do |adv|
          ad_detail_hash.merge!("#{adv.id}" => adv.commission.to_f.round(2))
        end

        imported_values = []

        add_impressions.each do |each_rec|
          count -= 1
          begin
            each_rec_arr = JSON.parse(each_rec)["args"]
            each_rec_class = each_rec_arr[0]
            each_rec_detail = each_rec_arr[1]

            if each_rec_class == "AddImpression"
              impression = AddImpression.create_new_record(each_rec_detail)

              url_params = Advertisement.reverse_make_url_params(impression.params)
              url_params.symbolize_keys!
              impression_import << impression  if !impression.advertisement_id.blank?  # TODO: temporary disabled for optimization

              # Impression mongo
              impression_mongo = impression.attributes
              impression_mongo["_id"] = impression_mongo["id"].to_s
              impression_mongo.delete("id")

              #time fixes
              impression_mongo["impression_time"] = impression.impression_time.utc if impression.impression_time.is_a?(Time)
              impression_mongo["created_at"] = impression.created_at.utc if impression.created_at.is_a?(Time)
              impression_mongo["updated_at"] = impression.updated_at.utc if impression.updated_at.is_a?(Time)

              impression_mongo["tagging"] = impression.t.to_i
              impression_mongo["retargeting"] = impression.r.to_i
              impression_mongo["domain"] = Item.get_host_without_www(impression.hosted_site_url)
              impression_mongo["device"] = url_params[:device]
              impression_mongo["size"] = url_params[:size]
              impression_mongo["design_type"] = url_params[:page_type]
              impression_mongo["viewability"] = url_params[:v].blank? ? 101 : url_params[:v].to_i
              impression_mongo["video_impression_id"] = impression.video_impression_id
              impression_mongo["additional_details"] = impression.a
              impression_mongo["geo"] = impression.geo
              impression_mongo["is_rii"] = impression.having_related_items
              impression_mongo["visited"] = impression.visited if !impression.visited.blank?

              time = impression.impression_time.utc rescue Time.now
              date = time.to_date rescue ""
              hour = time.hour rescue ""
              publisher_id = impression.publisher_id.to_s

              if !impression.temp_user_id.blank? && !url_params[:gid].blank?
                cookie_match = CookieMatch.new(:plannto_user_id => impression.temp_user_id, :google_user_id => url_params[:gid], :match_source => "add_impression", :google_mapped => false)
                imported_values << cookie_match
              end

              if !impression.advertisement_id.blank?
                winning_price = impression.winning_price.to_f/1000000 rescue 0.0
                winning_price = winning_price.to_f.round(2)
                begin
                  commission = ad_detail_hash[impression.advertisement_id.to_s]

                  commission = commission.blank? ? 1 : commission.to_f
                  winning_price_com = winning_price.to_f + (winning_price.to_f * (commission/100))

                  winning_price_com = winning_price_com.to_f.round(2)
                rescue Exception => e
                  error_count += 1
                  winning_price_com = 0.0
                  if error_count > 10
                    raise e
                  end
                end

                if impression.video_impression_id.blank?
                  impression_import_mongo << impression_mongo
                else
                  video_comp_impression_import_mongo << impression_mongo
                end

                # For AggregatedImpression
                device_name = impression.device.to_s
                is_rii = impression_mongo["is_rii"].to_s
                ret_val = impression.r.to_i == 1
                visited = impression.visited.to_i == 1
                ad_size = impression_mongo["size"].to_s
                page_type = impression_mongo["design_type"].to_s

                current_hash = ads_hash["#{date}_#{impression.advertisement_id.to_s}"]

                if current_hash.blank?
                  ads_hash["#{date}_#{impression.advertisement_id.to_s}"] = {}
                  current_hash = ads_hash["#{date}_#{impression.advertisement_id.to_s}"]
                end

                current_hash.merge!("agg_date" => "#{date}", "ad_id" => impression.advertisement_id.to_s)

                current_hash.merge!("total_imp" => current_hash["total_imp"].to_i + 1, "total_costs" => current_hash["total_costs"].to_f + winning_price.to_f, "total_costs_wc" => current_hash["total_costs_wc"].to_f + winning_price_com)

                current_hash["hours"] = {} if current_hash["hours"].blank?
                curr_hour = current_hash["hours"]["#{hour}"]
                if curr_hour.blank?
                  current_hash["hours"].merge!({"#{hour}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_hour.merge!({"imp" => curr_hour["imp"].to_i + 1, "costs" => curr_hour["costs"].to_f + winning_price.to_f})
                end

                current_hash["device"] = {} if current_hash["device"].blank?
                curr_device = current_hash["device"]["#{device_name}"]
                if curr_device.blank?
                  current_hash["device"].merge!({"#{device_name}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_device.merge!({"imp" => curr_device["imp"].to_i + 1, "costs" => curr_device["costs"].to_f + winning_price.to_f})
                end

                current_hash["size"] = {} if current_hash["size"].blank?
                curr_size = current_hash["size"]["#{ad_size}"]
                if curr_size.blank?
                  current_hash["size"].merge!({"#{ad_size}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_size.merge!({"imp" => curr_size["imp"].to_i + 1, "costs" => curr_size["costs"].to_f + winning_price.to_f})
                end

                current_hash["page_types"] = {} if current_hash["page_types"].blank?
                curr_page_type = current_hash["page_types"]["#{page_type}"]
                if curr_page_type.blank?
                  current_hash["page_types"].merge!("#{page_type}" => {"#{ad_size}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_page_type_size = curr_page_type["#{ad_size}"]
                  if curr_page_type_size.blank?
                    curr_page_type.merge!("#{ad_size}" => {"imp" => 1, "costs" => winning_price.to_f})
                  else
                    curr_page_type_size.merge!({"imp" => curr_page_type_size["imp"].to_i + 1, "costs" => curr_page_type_size["costs"].to_f + winning_price.to_f})
                  end
                end

                current_hash["rii"] = {} if current_hash["rii"].blank?
                curr_rii = current_hash["rii"]["#{is_rii}"]
                if curr_rii.blank?
                  current_hash["rii"].merge!({"#{is_rii}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_rii.merge!({"imp" => curr_rii["imp"].to_i + 1, "costs" => curr_rii["costs"].to_f + winning_price.to_f})
                end

                current_hash["ret"] = {} if current_hash["ret"].blank?
                curr_ret = current_hash["ret"]["#{ret_val}"]
                if curr_ret.blank?
                  current_hash["ret"].merge!({"#{ret_val}" => {"imp" => 1, "costs" => winning_price.to_f}})
                else
                  curr_ret.merge!({"imp" => curr_ret["imp"].to_i + 1, "costs" => curr_ret["costs"].to_f + winning_price.to_f})
                end

                if visited == true
                  current_hash["visited"] = {} if current_hash["visited"].blank?
                  curr_visited = current_hash["visited"]["#{visited}"]
                  if curr_visited.blank?
                    current_hash["visited"].merge!({"#{visited}" => {"imp" => 1, "costs" => winning_price.to_f}})
                  else
                    curr_visited.merge!({"imp" => curr_visited["imp"].to_i + 1, "costs" => curr_visited["costs"].to_f + winning_price.to_f})
                  end
                end

                #Items hash
                current_item_hash = items_hash["item_#{date}_#{impression.advertisement_id.to_s}"]

                if current_item_hash.blank?
                  items_hash["item_#{date}_#{impression.advertisement_id.to_s}"] = {}
                  current_item_hash = items_hash["item_#{date}_#{impression.advertisement_id.to_s}"]
                end

                current_item_hash.merge!("agg_date" => "#{date}", "ad_id" => impression.advertisement_id.to_s, "agg_type" => "Item")

                current_item_hash["agg_coll"] = {} if current_item_hash["agg_coll"].blank?
                curr_item = current_item_hash["agg_coll"]["#{impression.item_id.to_s}"]

                if curr_item.blank?
                  current_item_hash["agg_coll"].merge!("#{impression.item_id.to_s}" => {"imp" => 1})
                else
                  curr_item.merge!("imp"=> curr_item["imp"].to_i + 1)
                end

                #Domains hash
                domain = impression_mongo["domain"].to_s
                domain = domain.gsub(".", "^")

                current_domain_hash = domains_hash["domain_#{date}_#{impression.advertisement_id.to_s}"]

                if current_domain_hash.blank?
                  domains_hash["domain_#{date}_#{impression.advertisement_id.to_s}"] = {}
                  current_domain_hash = domains_hash["domain_#{date}_#{impression.advertisement_id.to_s}"]
                end

                current_domain_hash.merge!("agg_date" => "#{date}", "ad_id" => impression.advertisement_id.to_s, "agg_type" => "Domain")

                current_domain_hash["agg_coll"] = {} if current_domain_hash["agg_coll"].blank?
                curr_domain = current_domain_hash["agg_coll"]["#{domain}"]

                if curr_domain.blank?
                  current_domain_hash["agg_coll"].merge!("#{domain}" => {"imp" => 1})
                else
                  curr_domain.merge!("imp"=> curr_domain["imp"].to_i + 1)
                end

                #Sid hash
                sid = impression.sid.to_s

                current_sid_hash = sid_hash["sid_#{date}_#{impression.advertisement_id.to_s}"]

                if current_sid_hash.blank?
                  sid_hash["sid_#{date}_#{impression.advertisement_id.to_s}"] = {}
                  current_sid_hash = sid_hash["sid_#{date}_#{impression.advertisement_id.to_s}"]
                end

                current_sid_hash.merge!("agg_date" => "#{date}", "ad_id" => impression.advertisement_id.to_s, "agg_type" => "Sid")

                current_sid_hash["agg_coll"] = {} if current_sid_hash["agg_coll"].blank?
                curr_sid = current_sid_hash["agg_coll"]["#{sid}"]

                if curr_sid.blank?
                  current_sid_hash["agg_coll"].merge!("#{sid}" => {"imp" => 1})
                else
                  curr_sid.merge!("imp"=> curr_sid["imp"].to_i + 1)
                end
              else
                current_hash = publisher_hash["publisher_#{date}"]

                if current_hash.blank?
                  publisher_hash["publisher_#{date}"] = {}
                  current_hash = publisher_hash["publisher_#{date}"]
                end

                current_hash.merge!("agg_date" => "#{date}", "ad_id" => "", "for_pub" => true)

                current_hash.merge!("total_imp" => current_hash["total_imp"].to_i + 1)

                current_hash["publishers"] = {} if current_hash["publishers"].blank?
                curr_publisher = current_hash["publishers"]["#{publisher_id.to_s}"]

                if curr_publisher.blank?
                  current_hash["publishers"].merge!("#{publisher_id.to_s}" => {"imp" => 1})
                else
                  curr_publisher.merge!("imp"=> curr_publisher["imp"].to_i + 1)
                end
              end

              if impression.advertisement_type == "advertisement" || impression.advertisement_type == "fashion"
                ad_impressions_list << impression
              elsif impression.advertisement_type != "advertisement"
                non_ad_impressions_list << impression
              end
            elsif each_rec_class == "Click"
              click = Click.create_new_record(each_rec_detail)
              unless click.blank?
                clicks_import << click

                click_mongo = click.attributes
                click_mongo["ad_impression_id"] = click_mongo["impression_id"].to_s
                click_mongo["video_impression_id"] = click.video_impression_id
                click_mongo["temp_user_id"] = click.temp_user_id
                click_mongo["item_id"] = click.item_id
                click_mongo.delete("impression_id")
                clicks_import_mongo << click_mongo if !click.advertisement_id.blank?

                time = click.timestamp.utc rescue Time.now
                date = time.to_date rescue ""
                hour = time.hour rescue ""
                publisher_id = click.publisher_id.to_s

                click_impression = AddImpression.where(:id => click.impression_id).last

                if click_impression.blank?
                  click_impression = impression_import.select {|each_imp| each_imp.id.to_s == click.impression_id.to_s}.last
                  click_impression = non_ad_impressions_list.select {|each_imp| each_imp.id.to_s == click.impression_id.to_s}.last if click_impression.blank?
                end

                if !click_impression.blank?
                  time = click_impression.impression_time.utc rescue Time.now
                  date = time.to_date rescue ""
                  hour = time.hour rescue ""
                  publisher_id = click_impression.publisher_id.to_s if !click_impression.publisher_id.blank?
                end


                if !click.advertisement_id.blank?
                  # device_name = impression_mongo["device"]
                  # is_rii = impression_mongo["is_rii"]
                  ret_val = click.r.to_i == 1
                  is_rii = click.advertisement.having_related_items rescue false

                  current_hash = ads_hash["#{date}_#{click.advertisement_id.to_s}"]
                  if current_hash.blank?
                    ads_hash["#{date}_#{click.advertisement_id.to_s}"] = {}
                    current_hash = ads_hash["#{date}_#{click.advertisement_id.to_s}"]
                  end

                  current_hash.merge!("agg_date" => "#{date}", "ad_id" => click.advertisement_id.to_s)
                  current_hash.merge!({"total_clicks" => current_hash["total_clicks"].to_i + 1})

                  current_hash["hours"] = {} if current_hash["hours"].blank?
                  curr_hour = current_hash["hours"]["#{hour}"]
                  if curr_hour.blank?
                    current_hash["hours"].merge!({"#{hour}" => {"clicks" => 1}})
                  else
                    curr_hour.merge!({"clicks" => curr_hour["clicks"].to_i + 1})
                  end

                  if !click_impression.blank?
                    url_params = Advertisement.reverse_make_url_params(click_impression.params) rescue {}
                    url_params.symbolize_keys!

                    device_name = url_params[:device].to_s
                    ad_size = url_params[:size].to_s
                    page_type = url_params[:page_type].to_s

                    current_hash["device"] = {} if current_hash["device"].blank?
                    curr_device = current_hash["device"]["#{device_name}"]
                    if curr_device.blank?
                      current_hash["device"].merge!({"#{device_name}" => {"clicks" => 1}})
                    else
                      curr_device.merge!({"clicks" => curr_device["clicks"].to_i + 1})
                    end

                    current_hash["size"] = {} if current_hash["size"].blank?
                    curr_size = current_hash["size"]["#{ad_size}"]
                    if curr_size.blank?
                      current_hash["size"].merge!({"#{ad_size}" => {"clicks" => 1}})
                    else
                      curr_size.merge!({"clicks" => curr_size["clicks"].to_i + 1})
                    end

                    current_hash["page_types"] = {} if current_hash["page_types"].blank?
                    curr_page_type = current_hash["page_types"]["#{page_type}"]
                    if curr_page_type.blank?
                      current_hash["page_types"].merge!("#{page_type}" => {"#{ad_size}" => {"clicks" => 1}})
                    else
                      curr_page_type_size = curr_page_type["#{ad_size}"]
                      if curr_page_type_size.blank?
                        curr_page_type.merge!("#{ad_size}" => {"clicks" => 1})
                      else
                        curr_page_type_size.merge!({"clicks" => curr_page_type_size["clicks"].to_i + 1})
                      end
                    end

                    if ret_val == false
                      ret_val = url_params[:r].to_i == 1
                    end
                  end

                  current_hash["rii"] = {} if current_hash["rii"].blank?
                  curr_rii = current_hash["rii"]["#{is_rii}"]
                  if curr_rii.blank?
                    current_hash["rii"].merge!({"#{is_rii}" => {"clicks" => 1}})
                  else
                    curr_rii.merge!({"clicks" => curr_rii["clicks"].to_i + 1})
                  end

                  current_hash["ret"] = {} if current_hash["ret"].blank?
                  curr_ret = current_hash["ret"]["#{ret_val}"]
                  if curr_ret.blank?
                    current_hash["ret"].merge!({"#{ret_val}" => {"clicks" => 1}})
                  else
                    curr_ret.merge!({"clicks" => curr_ret["clicks"].to_i + 1})
                  end

                  #Items hash
                  current_item_hash = items_hash["item_#{date}_#{click.advertisement_id.to_s}"]

                  if current_item_hash.blank?
                    items_hash["item_#{date}_#{click.advertisement_id.to_s}"] = {}
                    current_item_hash = items_hash["item_#{date}_#{click.advertisement_id.to_s}"]
                  end

                  current_item_hash.merge!("agg_date" => "#{date}", "ad_id" => click.advertisement_id.to_s, "agg_type" => "Item")

                  current_item_hash["agg_coll"] = {} if current_item_hash["agg_coll"].blank?
                  curr_item = current_item_hash["agg_coll"]["#{click.item_id.to_s}"]

                  if curr_item.blank?
                    current_item_hash["agg_coll"].merge!("#{click.item_id.to_s}" => {"clicks" => 1})
                  else
                    curr_item.merge!("clicks"=> curr_item["clicks"].to_i + 1)
                  end

                  #Domains hash
                  domain_url = click.hosted_site_url
                  if domain_url.blank? || domain_url.include?("plannto.com") || domain_url.include?("localhost") || !click_impression.blank?
                    domain_url = click_impression.hosted_site_url.to_s if !click_impression.hosted_site_url.blank?
                  end

                  domain = Item.get_host_without_www(domain_url)
                  domain = domain.to_s.gsub(".", "^")

                  current_domain_hash = domains_hash["domain_#{date}_#{click.advertisement_id.to_s}"]

                  if current_domain_hash.blank?
                    domains_hash["domain_#{date}_#{click.advertisement_id.to_s}"] = {}
                    current_domain_hash = domains_hash["domain_#{date}_#{click.advertisement_id.to_s}"]
                  end

                  current_domain_hash.merge!("agg_date" => "#{date}", "ad_id" => click.advertisement_id.to_s, "agg_type" => "Domain")

                  current_domain_hash["agg_coll"] = {} if current_domain_hash["agg_coll"].blank?
                  curr_domain = current_domain_hash["agg_coll"]["#{domain}"]

                  if curr_domain.blank?
                    current_domain_hash["agg_coll"].merge!("#{domain}" => {"clicks" => 1})
                  else
                    curr_domain.merge!("clicks"=> curr_domain["clicks"].to_i + 1)
                  end

                  #Sid hash
                  sid = click.sid.to_s

                  current_sid_hash = sid_hash["sid_#{date}_#{click.advertisement_id.to_s}"]

                  if current_sid_hash.blank?
                    sid_hash["sid_#{date}_#{click.advertisement_id.to_s}"] = {}
                    current_sid_hash = sid_hash["sid_#{date}_#{click.advertisement_id.to_s}"]
                  end

                  current_sid_hash.merge!("agg_date" => "#{date}", "ad_id" => click.advertisement_id.to_s, "agg_type" => "Sid")

                  current_sid_hash["agg_coll"] = {} if current_sid_hash["agg_coll"].blank?
                  curr_sid = current_sid_hash["agg_coll"]["#{sid}"]

                  if curr_sid.blank?
                    current_sid_hash["agg_coll"].merge!("#{sid}" => {"clicks" => 1})
                  else
                    curr_sid.merge!("clicks"=> curr_sid["clicks"].to_i + 1)
                  end

                else
                  current_pub_hash = publisher_hash["publisher_#{date}"]

                  if current_pub_hash.blank?
                    publisher_hash["publisher_#{date}"] = {}
                    current_pub_hash = publisher_hash["publisher_#{date}"]
                  end

                  current_pub_hash.merge!("agg_date" => "#{date}", "ad_id" => "", "for_pub" => true)
                  current_pub_hash.merge!({"total_clicks" => current_pub_hash["total_clicks"].to_i + 1})

                  current_pub_hash["publishers"] = {} if current_pub_hash["publishers"].blank?
                  curr_publisher = current_pub_hash["publishers"]["#{publisher_id.to_s}"]

                  if curr_publisher.blank?
                    current_pub_hash["publishers"].merge!("#{publisher_id.to_s}" => {"clicks" => 1})
                  else
                    curr_publisher.merge!("clicks"=> curr_publisher["clicks"].to_i + 1)
                  end
                end
              end
            elsif each_rec_class == "VideoImpression"
              video_imp = VideoImpression.create_new_record(each_rec_detail)
              video_imp_import << video_imp

              impression = video_imp

              url_params = Advertisement.reverse_make_url_params(impression.params)
              url_params.symbolize_keys!
              impression.device = url_params[:device]

              # Impression mongo
              impression_mongo = impression.attributes
              impression_mongo["_id"] = impression_mongo["id"].to_s
              impression_mongo.delete("id")

              #time fixes
              impression_mongo["impression_time"] = impression.impression_time.utc if impression.impression_time.is_a?(Time)
              impression_mongo["created_at"] = impression.created_at.utc if impression.created_at.is_a?(Time)
              impression_mongo["updated_at"] = impression.updated_at.utc if impression.updated_at.is_a?(Time)

              impression_mongo["tagging"] = impression.t.to_i
              impression_mongo["retargeting"] = impression.r.to_i
              impression_mongo["domain"] = Item.get_host_without_www(impression.hosted_site_url)
              impression_mongo["device"] = url_params[:device]
              impression_mongo["size"] = url_params[:size]
              impression_mongo["design_type"] = url_params[:page_type]
              impression_mongo["viewability"] = url_params[:v].blank? ? 101 : url_params[:v].to_i
              impression_mongo["additional_details"] = impression.a
              impression_import_mongo << impression_mongo
            elsif each_rec_class == "UpdateImpression"
              obj_params = each_rec_detail
              unless obj_params.is_a?(Hash)
                obj_params = JSON.parse(obj_params)
              end
              obj_params = obj_params.symbolize_keys

              impression_id = obj_params.delete(:impression_id)

              add_impression = AddImpression.where(:id => impression_id).last

              if add_impression.blank?
                add_impression = impression_import.select {|each_imp| each_imp.id.to_s == impression_id.to_s}.last
                add_impression = non_ad_impressions_list.select {|each_imp| each_imp.id.to_s == impression_id.to_s}.last if add_impression.blank?
              end

              if !add_impression.blank?
                time = add_impression.impression_time.utc rescue Time.now
                imp_date = time.to_date rescue ""
                hour = time.hour rescue ""
                imp_advertisement_id = add_impression.advertisement_id.to_s

                current_hash = ads_hash["#{imp_date}_#{imp_advertisement_id}"]
                if current_hash.blank?
                  ads_hash["#{imp_date}_#{imp_advertisement_id}"] = {}
                  current_hash = ads_hash["#{imp_date}_#{imp_advertisement_id}"]
                end

                current_hash.merge!("agg_date" => "#{date}", "ad_id" => imp_advertisement_id)

                visited = obj_params[:visited].to_i == "true"
                expanded = obj_params[:expanded].to_i == "true"

                if visited == true
                  current_hash["visited"] = {} if current_hash["visited"].blank?
                  curr_visited = current_hash["visited"]["#{visited}"]
                  if curr_visited.blank?
                    current_hash["visited"].merge!({"#{visited}" => {"imp" => 1, "costs" => winning_price.to_f}})
                  else
                    curr_visited.merge!({"imp" => curr_visited["imp"].to_i + 1, "costs" => curr_visited["costs"].to_f + winning_price.to_f})
                  end
                end

                if expanded == true
                  current_hash["expanded"] = {} if current_hash["expanded"].blank?
                  curr_expanded = current_hash["expanded"]["#{expanded}"]
                  if curr_expanded.blank?
                    current_hash["expanded"].merge!({"#{expanded}" => {"imp" => 1, "costs" => winning_price.to_f}})
                  else
                    curr_expanded.merge!({"imp" => curr_expanded["imp"].to_i + 1, "costs" => curr_expanded["costs"].to_f + winning_price.to_f})
                  end
                end
              end

              # update_impressions << {impression_id => obj_params} if !impression_id.blank?
            end
          rescue Exception => e
            error_count += 1
            p "There was problem while running impressions process => #{e.backtrace}"
            if error_count > 10
              raise e
            end
          end
          p "Remaining click_or_impressions Count - #{count}"
        end

        imported_values = imported_values.reverse.uniq(&:plannto_user_id)

        result = CookieMatch.import(imported_values)

        $redis_rtb.pipelined do
          imported_values.each do |cookie_detail|
            $redis_rtb.set("cm:#{cookie_detail.google_user_id}", cookie_detail.plannto_user_id)
            $redis_rtb.expire("cm:#{cookie_detail.google_user_id}", 1.weeks)
          end
        end

        begin
          # AggregatedImpression
          ads_hash.each do |key, val|
            agg_imp = AggregatedImpression.where(:agg_date => val["agg_date"], :ad_id => val["ad_id"]).last

            if agg_imp.blank?
              agg_imp = AggregatedImpression.new(val)
              agg_imp.save!
            else
              agg_imp.hours = Advertisement.combine_hash(agg_imp.hours, val["hours"]) if !val["hours"].blank?
              agg_imp.device = Advertisement.combine_hash(agg_imp.device, val["device"]) if !val["device"].blank?
              agg_imp.size = Advertisement.combine_hash(agg_imp.size, val["size"]) if !val["size"].blank?
              agg_imp.page_types = Advertisement.combine_hash_multi_hash(agg_imp.page_types, val["page_types"]) if !val["page_types"].blank?
              agg_imp.ret = Advertisement.combine_hash(agg_imp.ret, val["ret"]) if !val["ret"].blank?
              agg_imp.rii = Advertisement.combine_hash(agg_imp.rii, val["rii"]) if !val["rii"].blank?
              agg_imp.visited = Advertisement.combine_hash(agg_imp.visited, val["visited"]) if !val["visited"].blank?
              agg_imp.expanded = Advertisement.combine_hash(agg_imp.expanded, val["expanded"]) if !val["expanded"].blank?

              agg_imp.total_imp = agg_imp.total_imp.to_i + val["total_imp"].to_i
              agg_imp.total_clicks = agg_imp.total_clicks.to_i + val["total_clicks"].to_i
              agg_imp.total_costs = (agg_imp.total_costs.to_f + val["total_costs"].to_f).to_f.round(2)
              agg_imp.total_costs_wc = (agg_imp.total_costs_wc.to_f + val["total_costs_wc"].to_f).to_f.round(2)

              agg_imp.save!
            end
          end

          publisher_hash.each do |key, val|
            agg_imp = AggregatedImpression.where(:agg_date => val["agg_date"], :ad_id => nil, :for_pub => true).last

            if agg_imp.blank?
              agg_imp = AggregatedImpression.new(val)
              agg_imp.save!
            else
              agg_imp.publishers = Advertisement.combine_hash(agg_imp.publishers, val["publishers"]) if !val["publishers"].blank?
              agg_imp.total_imp = agg_imp.total_imp.to_i + val["total_imp"].to_i
              agg_imp.total_clicks = agg_imp.total_clicks.to_i + val["total_clicks"].to_i
              agg_imp.save!
            end
          end

          items_hash.each do |key, val|
            agg_imp = AggregatedImpressionByType.where(:agg_date => val["agg_date"], :ad_id => val["ad_id"], :agg_type => val["agg_type"]).last

            if agg_imp.blank?
              agg_imp = AggregatedImpressionByType.new(val)
              agg_imp.save!
            else
              agg_imp.agg_coll = Advertisement.combine_hash(agg_imp.agg_coll, val["agg_coll"]) if !val["agg_coll"].blank?
              agg_imp.save!
            end
          end

          domains_hash.each do |key, val|
            domain_agg_imp = AggregatedImpressionByType.where(:agg_date => val["agg_date"], :ad_id => val["ad_id"], :agg_type => val["agg_type"]).last

            if domain_agg_imp.blank?
              domain_agg_imp = AggregatedImpressionByType.new(val)
              domain_agg_imp.save!
            else
              old_coll = domain_agg_imp.agg_coll
              old_coll = Hash[old_coll.map {|k, v| [k.gsub(".", "^"), v] }]
              agg_coll = Advertisement.combine_hash(old_coll, val["agg_coll"]) if !val["agg_coll"].blank?
              agg_coll = Hash[agg_coll.map {|k, v| [k.gsub(".", "^"), v] }]
              domain_agg_imp.agg_coll = agg_coll
              domain_agg_imp.save!
            end
          end

          sid_hash.each do |key, val|
            sid_agg_imp = AggregatedImpressionByType.where(:agg_date => val["agg_date"], :ad_id => val["ad_id"], :agg_type => val["agg_type"]).last

            if sid_agg_imp.blank?
              sid_agg_imp = AggregatedImpressionByType.new(val)
              sid_agg_imp.save!
            else
              sid_agg_imp.agg_coll = Advertisement.combine_hash(sid_agg_imp.agg_coll, val["agg_coll"]) if !val["agg_coll"].blank?
              sid_agg_imp.save!
            end
          end
        rescue Exception => e
          p "fixes for => #{e.backtrace}"
          error_count += 1
          if error_count > 10
            raise e
          end
        end

        # Process bulk insert for mongo collection impression
        AddImpression.import(impression_import)

        # TODO: temporary disabled for optimization
        # begin
        #   AdImpression.collection.insert(impression_import_mongo, { ordered: false })
        # rescue Exception => e
        #   impression_import_mongo.each do |each_loop|
        #     begin
        #       AdImpression.collection.insert(each_loop)
        #     rescue Exception => e
        #       p e
        #     end
        #   end
        # end

        video_comp_impression_import_mongo.each do |each_comp_imp|
          begin
            vid_imp = AdImpression.where("_id" => each_comp_imp["video_impression_id"]).first

            if !vid_imp.blank?
              vid_imp.m_companion_impressions << MCompanionImpression.new(:timestamp => each_comp_imp["timestamp"])
            else
              MCompanionImpression.collection.insert(:timestamp => each_comp_imp["timestamp"], :_id => each_comp_imp["_id"], :video_impression_id => each_comp_imp["video_impression_id"])
            end
          rescue Exception => e
            error_count += 1
            p "rescue while comp mongodb insert"
            if error_count > 10
              raise e
            end
          end
        end


        # TODO: temporary disabled for optimization
        # ad_impressions_list_values = $redis_rtb.pipelined do
        #   ad_impressions_list.each do |each_impression|
        #     $redis_rtb.get("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}")
        #   end
        # end
        #
        # impression_details = []
        # ad_impressions_list.each_with_index do |imp, index|
        #   appearance_count = ad_impressions_list_values[index].to_i
        #   if (imp.video_impression_id.blank? && (imp.t == 1 || imp.r == 1 || appearance_count > 0 || !imp.a.blank? || imp.video.to_s == "true" || !imp.geo.blank? || !imp.device.blank? || !imp.having_related_items.blank?))
        #     impression_details << ImpressionDetail.new(:impression_id => imp.id, :tagging => imp.t, :retargeting => imp.r, :pre_appearance_count => appearance_count, :additional_details => imp.a, :video => imp.video, :video_impression_id => imp.video_impression_id, :geo => imp.geo, :device => imp.device, :having_related_items => imp.having_related_items)
        #   end
        # end
        #
        # ImpressionDetail.import(impression_details)

        $redis_rtb.pipelined do
          impression_import.each do |each_impression|
            if (each_impression.advertisement_type == "advertisement" && !each_impression.temp_user_id.blank? && !each_impression.advertisement_id.blank? && each_impression.video_impression_id.blank?)
              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",2.weeks)

              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1.day)
            end
          end
        end


        #buying list update for non ad impressions

        p "Started buying list update for non ad impressions"

        redis_rtb_hash = {}
        plannto_user_detail_hash = {}
        plannto_autoportal_hash = {}
        cookie_matches_plannto_ids = []
        non_ad_impressions_list.each do |impression|
          begin
            article_content = ArticleContent.find_by_sql("select itemtype_id,sub_type,group_concat(icc.item_id) all_item_ids, ac.id from article_contents ac inner join contents c on ac.id = c.id
inner join item_contents_relations_cache icc on icc.content_id = ac.id
where url = '#{impression.hosted_site_url}' group by ac.id").first

            unless article_content.blank?
              user_id = impression.temp_user_id
              type = article_content.sub_type
              item_ids = article_content.all_item_ids.to_s rescue ""
              itemtype_id = article_content.itemtype_id

              itemtype_name = article_content.itemtype.itemtype.to_s rescue ""
              if !valid_item_types.include?(itemtype_name)
                splt_item_ids = item_ids.to_s.split(",").compact
                match_item_ids = valid_item_ids & splt_item_ids
                if match_item_ids.blank?
                  p "-------------------------- Skip buying list process --------------------------"
                else
                  item_ids = match_item_ids.join(",")

                  redis_hash, plannto_user_detail_hash_new, plannto_autoportal_hash_new, cookie_matches_plannto_id = UserAccessDetail.update_buying_list(user_id, impression.hosted_site_url, type, item_ids, nil, "plannto", itemtype_id)
                  redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
                  plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
                  plannto_autoportal_hash.merge!(plannto_autoportal_hash_new) if plannto_autoportal_hash_new.blank? || !plannto_autoportal_hash_new.values.map(&:blank?).include?(true)
                  cookie_matches_plannto_ids << cookie_matches_plannto_id if cookie_matches_plannto_id.blank?
                end
              end

              # redis_hash, plannto_user_detail_hash_new = UserAccessDetail.update_buying_list(user_id, impression.hosted_site_url, type, item_ids, nil, "plannto", itemtype_id)
              # redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
              # plannto_user_detail_hash.merge!(plannto_user_detail_hash_new) if !plannto_user_detail_hash_new.values.map(&:blank?).include?(true)
            end
          rescue Exception => e
            error_count += 1
            p "Error invalid url errors => #{impression.hosted_site_url}"
            if error_count > 10
              raise e
            end
          end
        end

        # Redis Rtb update
        $redis_rtb.pipelined do
          redis_rtb_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.hincrby(key, "ap_c", 1)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        $redis_rtb.pipelined do
          plannto_user_detail_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        $redis_rtb.pipelined do
          plannto_autoportal_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        p "-------------------------------- CookieMatch In User Access Detail ------------------------------"

        if !cookie_matches_plannto_ids.compact!.blank?
          begin
            cookie_matches_plannto_ids = cookie_matches_plannto_ids.uniq
            cookie_matches = CookieMatch.where(:plannto_user_id => cookie_matches_plannto_ids)
            # cookie_matches.update_all(:updated_at => Time.now)
            cookie_matches.each do |each_rec|
              each_rec.touch
            end

            $redis_rtb.pipelined do
              cookie_matches.each do |cookie_match|
                if !cookie_match.google_user_id.blank? && !cookie_match.plannto_user_id.blank?
                  $redis_rtb.set("cm:#{cookie_match.google_user_id}", cookie_match.plannto_user_id)
                  $redis_rtb.expire("cm:#{cookie_match.google_user_id}", 1.weeks)
                end
              end
            end
          rescue Exception => e
            p "Error processing cookie match"
          end
        end

        p "Completed buying list update for non ad impressions"

        p "Started Click Detail Process"

        clicks_details = []
        clicks_import.each do |each_click|
          begin
            if !each_click.t.blank? || !each_click.r.blank? || each_click.ic.to_i >0 || !each_click.a.blank?
              clicks_import = clicks_import - [each_click]
              each_click.save!
              click_detail = ClickDetail.new(:click_id => each_click.id, :tagging => each_click.t, :retargeting => each_click.r, :pre_appearance_count => each_click.ic, :additional_details => each_click.a)
              clicks_details << click_detail
            end
          rescue Exception => e
            p "Problem while creating click detail"
          end
        end

        Click.import(clicks_import)
        ClickDetail.import(clicks_details)

        clicks_import_mongo.each do |each_click_mongo|
          begin
            if !each_click_mongo["temp_user_id"].blank?
              #Updating PUserDetail
              plannto_user_detail = PUserDetail.where(:pid => each_click_mongo["temp_user_id"]).to_a.last

              if (!plannto_user_detail.blank? && plannto_user_detail.gid.blank?)
                cookie_match = CookieMatch.where(:plannto_user_id => each_click_mongo["temp_user_id"]).last
                if !cookie_match.blank? && !cookie_match.google_user_id.blank?
                  plannto_user_detail.gid = cookie_match.google_user_id
                  plannto_user_detail.lad = Time.now
                  plannto_user_detail.save!
                end
              elsif plannto_user_detail.blank?
                plannto_user_detail = PUserDetail.new(:pid => each_click_mongo["temp_user_id"])
                cookie_match = CookieMatch.where(:plannto_user_id => each_click_mongo["temp_user_id"]).last
                if !cookie_match.blank? && !cookie_match.google_user_id.blank?
                  plannto_user_detail.gid = cookie_match.google_user_id
                end
                plannto_user_detail.lad = Time.now
                plannto_user_detail.save!
              end
            end

            if !plannto_user_detail.blank?
              agg_info = {}
              new_m_agg_info = ""
              itemtype_id = nil
              #plannto user details
              if !each_click_mongo["item_id"].blank?
                itemtype = Item.where(:id => each_click_mongo["item_id"]).select(:itemtype_id).first
                itemtype_id = itemtype.itemtype_id rescue ""
              end

              if !itemtype_id.blank?
                agg_info = {"#{itemtype_id}" => 1}
                new_m_agg_info = "#{itemtype_id}:1"

                i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
                if i_type.blank?
                  plannto_user_detail.i_types << IType.new(:itemtype_id => itemtype_id, :fad => Date.today)
                  i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
                end

                ci_ids = i_type.ci_ids
                ci_ids = ci_ids.blank? ? [each_click_mongo["item_id"].to_i] : (ci_ids + [each_click_mongo["item_id"].to_i])
                ci_ids = ci_ids.map(&:to_i).compact.uniq
                i_type.ci_ids = ci_ids
                i_type.lcd = Date.today
                i_type.save!
              end

              if !new_m_agg_info.blank?
                m_agg_info = plannto_user_detail.ai.to_s
                m_agg_info_arr = m_agg_info.split(",")
                m_agg_info_arr << new_m_agg_info
                plannto_user_detail.ai = m_agg_info_arr.uniq.join(",")
              end

              # plannto_user_detail.skip_duplicate_update = true
              plannto_user_detail.lad = Time.now
              plannto_user_detail.save!
            end

            if each_click_mongo["video_impression_id"].blank?
              ad_impression_mon = AdImpression.where(:_id => each_click_mongo["ad_impression_id"]).first
              unless ad_impression_mon.blank?
                each_click_mongo.delete("ad_impression_id")

                ad_impression_mon.m_clicks << MClick.new(:timestamp => each_click_mongo["timestamp"])
              end
            else
              ad_impression_mon = AdImpression.where(:_id => each_click_mongo["video_impression_id"]).first
              unless ad_impression_mon.blank?
                click_imp = {:timestamp => each_click_mongo["timestamp"]}
                if each_click_mongo["video_impression_id"] != each_click_mongo["ad_impression_id"]
                  click_imp.merge!({:video_impression_id => each_click_mongo["ad_impression_id"]})
                end

                ad_impression_mon.m_clicks << MClick.new(click_imp)
              end
            end
          rescue Exception => e
            error_count += 1
            p "Error while process click mongo"
            if error_count > 10
              raise e
            end
          end
        end

        p "Completed Click Detail Process"

        VideoImpression.import(video_imp_import)

        $redis_rtb.pipelined do
          video_imp_import.each do |each_impression|
            if (each_impression.advertisement_type == "video_advertisement" && !each_impression.temp_user_id.blank? && !each_impression.advertisement_id.blank?)
              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",2.weeks)

              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1.day)
            end
          end
        end

        $redis.ltrim("resque:queue:create_impression_and_click", add_impressions.count, -1)
        length = length - add_impressions.count
        p "*********************************** Remaining ImpressionAndClick Length - #{length} **********************************"
      end while length > 0

      # companion_impressions = MCompanionImpression.all
      $redis.set("bulk_process_add_impression_is_running", 0)
      Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc, "true")
    end
  end

=begin
  def self.future_bulk_process_impression_and_click()
    if $redis.get("bulk_process_add_impression_is_running").to_i == 0
      $redis.set("bulk_process_add_impression_is_running", 1)
      mins = $redis.llen("resque:queue:create_impression_and_click").to_i / 1000 rescue 30
      $redis.expire("bulk_process_add_impression_is_running", mins.minutes)
      length = $redis.llen("resque:queue:create_impression_and_click")
      count = length

      begin
        add_impressions = $redis.lrange("resque:queue:create_impression_and_click", 0, 1000)

        impression_import = []
        impression_import_mongo = []
        # video_comp_impression_import_mongo = []
        ad_impressions_list = []
        clicks_import = []
        clicks_import_mongo = []
        # video_imp_import = []
        non_ad_impressions_list = []
        ads_hash = {}
        publisher_hash = {}
        add_impressions.each do |each_rec|
          count -= 1
          begin
            each_rec_arr = JSON.parse(each_rec)["args"]
            each_rec_class = each_rec_arr[0]
            each_rec_detail = each_rec_arr[1]

            if each_rec_class == "AddImpression"
              impression = AddImpression.create_new_record(each_rec_detail)

              url_params = Advertisement.reverse_make_url_params(impression.params)
              impression_import << impression

              # Impression mongo
              impression_mongo = impression.attributes
              #time fixes
              impression_mongo["impression_time"] = impression.impression_time.utc if impression.impression_time.is_a?(Time)
              impression_mongo["retargeting"] = impression.r.to_i
              impression_mongo["device"] = url_params["device"]
              impression_mongo["is_rii"] = impression.having_related_items

              time = impression.impression_time.utc rescue Time.now
              date = time.to_date rescue ""
              hour = time.hour rescue ""

              if !impression.advertisement_id.blank?
                device_name = impression_mongo["device"]
                is_rii = impression_mongo["is_rii"]
                ret = impression.r.to_i == 1

                current_hash = ads_hash["#{date}_#{impression.advertisement_id.to_s}"]

                if current_hash.blank?
                  ads_hash["#{date}_#{impression.advertisement_id.to_s}"] = {}
                  current_hash = ads_hash["#{date}_#{impression.advertisement_id.to_s}"]
                end

                current_hash.merge!("agg_date" => "#{date}", "ad_id" => impression.advertisement_id.to_s)
                current_hash["hours"] = {} if current_hash["hours"].blank?
                curr_hour = current_hash["hours"]["#{hour}"]
                if curr_hour.blank?
                  current_hash["hours"].merge!({"#{hour}" => {"imp" => 1, "costs" => impression.winning_price.to_f}})
                else
                  curr_hour.merge!({"imp" => curr_hour["imp"].to_i + 1, "costs" => curr_hour["costs"].to_f + impression.winning_price.to_f})
                end

                current_hash["device"] = {} if current_hash["device"].blank?
                curr_device = current_hash["device"]["#{device_name}"]
                if curr_device.blank?
                  current_hash["device"].merge!({"#{device_name}" => {"imp" => 1, "costs" => impression.winning_price.to_f}})
                else
                  curr_device.merge!({"imp" => curr_device["imp"].to_i + 1, "costs" => curr_device["costs"].to_f + impression.winning_price.to_f})
                end

                current_hash["rii"] = {} if current_hash["rii"].blank?
                curr_rii = current_hash["rii"]["#{is_rii}"]
                if curr_rii.blank?
                  current_hash["rii"].merge!({"#{is_rii}" => {"imp" => 1, "costs" => impression.winning_price.to_f}})
                else
                  curr_rii.merge!({"imp" => curr_rii["imp"].to_i + 1, "costs" => curr_rii["costs"].to_f + impression.winning_price.to_f})
                end

                current_hash["ret"] = {} if current_hash["ret"].blank?
                curr_ret = current_hash["ret"]["#{ret}"]
                if curr_ret.blank?
                  current_hash["ret"].merge!({"#{ret}" => {"imp" => 1, "costs" => impression.winning_price.to_f}})
                else
                  curr_ret.merge!({"imp" => curr_ret["imp"].to_i + 1, "costs" => curr_ret["costs"].to_f + impression.winning_price.to_f})
                end
              else
                current_hash = publisher_hash["publisher_#{date}"]

                if current_hash.blank?
                  publisher_hash["publisher_#{date}"] = {}
                  current_hash = publisher_hash["publisher_#{date}"]
                end

                current_hash.merge!("agg_date" => "#{date}", "ad_id" => "", "for_pub" => true)

                current_hash["publishers"] = {} if current_hash["publishers"].blank?
                curr_publisher = current_hash["publishers"]["#{impression.publisher_id.to_s}"]

                if curr_publisher.blank?
                  current_hash["publishers"].merge!("#{impression.publisher_id.to_s}" => {"imp" => 1})
                else
                  curr_publisher.merge!("imp"=> curr_publisher["imp"].to_i + 1)
                end
              end

              if impression.advertisement_type == "advertisement" || impression.advertisement_type == "fashion"
                ad_impressions_list << impression
              elsif impression.advertisement_type != "advertisement"
                non_ad_impressions_list << impression
              end
            elsif each_rec_class == "Click"
              click = Click.create_new_record(each_rec_detail)
              unless click.blank?
                clicks_import << click

                # if !click.advertisement_id.blank?
                #   click_mongo = click.attributes
                #   click_mongo["ad_impression_id"] = click_mongo["impression_id"].to_s
                #   click_mongo.delete("impression_id")
                #   clicks_import_mongo << click_mongo
                # end

                click_mongo = click.attributes
                click_mongo["ad_impression_id"] = click_mongo["impression_id"].to_s
                click_mongo["video_impression_id"] = click.video_impression_id
                click_mongo["temp_user_id"] = click.temp_user_id
                click_mongo["item_id"] = click.item_id
                click_mongo.delete("impression_id")
                clicks_import_mongo << click_mongo if !click.advertisement_id.blank?

                time = click.timestamp.utc rescue Time.now
                date = time.to_date rescue ""
                hour = time.hour rescue ""

                if !click.advertisement_id.blank?
                  # device_name = impression_mongo["device"]
                  # is_rii = impression_mongo["is_rii"]
                  ret = click.r.to_i == 1
                  click_impression = AddImpression.where(:id => click.impression_id).last

                  current_hash = ads_hash["#{date}_#{click.advertisement_id.to_s}"]
                  if current_hash.blank?
                    ads_hash["#{date}_#{click.advertisement_id.to_s}"] = {}
                    current_hash = ads_hash["#{date}_#{click.advertisement_id.to_s}"]
                  end

                  current_hash.merge!("agg_date" => "#{date}", "ad_id" => click.advertisement_id.to_s)

                  current_hash["hours"] = {} if current_hash["hours"].blank?
                  curr_hour = current_hash["hours"]["#{hour}"]
                  if curr_hour.blank?
                    current_hash["hours"].merge!({"#{hour}" => {"clicks" => 1}})
                  else
                    curr_hour.merge!({"clicks" => curr_hour["clicks"].to_i + 1})
                  end

                  if !click_impression.blank?
                    url_params = Advertisement.reverse_make_url_params(click_impression.params) rescue {}

                    device_name = url_params["device"]
                    is_rii = click_impression.having_related_items

                    current_hash["device"] = {} if current_hash["device"].blank?
                    curr_device = current_hash["device"]["#{device_name}"]
                    if curr_device.blank?
                      current_hash["device"].merge!({"#{device_name}" => {"clicks" => 1}})
                    else
                      curr_device.merge!({"clicks" => curr_device["clicks"].to_i + 1})
                    end

                    current_hash["rii"] = {} if current_hash["rii"].blank?
                    curr_rii = current_hash["rii"]["#{is_rii}"]
                    if curr_rii.blank?
                      current_hash["rii"].merge!({"#{is_rii}" => {"clicks" => 1}})
                    else
                      curr_rii.merge!({"clicks" => curr_rii["clicks"].to_i + 1})
                    end
                  end

                  current_hash["ret"] = {} if current_hash["ret"].blank?
                  curr_ret = current_hash["ret"]["#{ret}"]
                  if curr_ret.blank?
                    current_hash["ret"].merge!({"#{ret}" => {"clicks" => 1}})
                  else
                    curr_ret.merge!({"clicks" => curr_ret["clicks"].to_i + 1})
                  end
                else
                  current_pub_hash = publisher_hash["publisher_#{date}"]

                  if current_pub_hash.blank?
                    publisher_hash["publisher_#{date}"] = {}
                    current_pub_hash = publisher_hash["publisher_#{date}"]
                  end

                  current_pub_hash.merge!("agg_date" => "#{date}", "ad_id" => "", "for_pub" => true)

                  current_pub_hash["publishers"] = {} if current_pub_hash["publishers"].blank?
                  curr_publisher = current_pub_hash["publishers"]["#{click.publisher_id.to_s}"]

                  if curr_publisher.blank?
                    current_pub_hash["publishers"].merge!("#{click.publisher_id.to_s}" => {"clicks" => 1})
                  else
                    curr_publisher.merge!("clicks"=> curr_publisher["clicks"].to_i + 1)
                  end
                end
              end
            end
          rescue Exception => e
            p "There was problem while running impressions process => #{e.backtrace}"
          end
          p "Remaining click_or_impressions Count - #{count}"
        end

        ads_hash.each do |key, val|
          agg_imp = AggregatedImpression.where(:agg_date => val["agg_date"], :ad_id => val["ad_id"]).last

          if agg_imp.blank?
            agg_imp = AggregatedImpression.new(val)
            agg_imp.save!
          else
            agg_imp.hours = Advertisemenet.combine_hash(agg_imp.hours, val["hours"]) if !val["hours"].blank?
            agg_imp.device = Advertisemenet.combine_hash(agg_imp.device, val["device"]) if !val["device"].blank?
            agg_imp.ret = Advertisemenet.combine_hash(agg_imp.ret, val["ret"]) if !val["ret"].blank?
            agg_imp.rii = Advertisemenet.combine_hash(agg_imp.rii, val["rii"]) if !val["rii"].blank?
            agg_imp.save!
          end
        end

        publisher_hash.each do |key, val|
          agg_imp = AggregatedImpression.where(:agg_date => val["agg_date"], :ad_id => nil, :for_pub => true).last

          if agg_imp.blank?
            agg_imp = AggregatedImpression.new(val)
            agg_imp.save!
          else
            agg_imp.publishers = Advertisement.combine_hash(agg_imp.publishers, val["publishers"]) if !val["publishers"].blank?
            agg_imp.save!
          end
        end

        # Impression Process
        AddImpression.import(impression_import)

        # video_comp_impression_import_mongo.each do |each_comp_imp|
        #   begin
        #     vid_imp = AdImpression.where("_id" => each_comp_imp["video_impression_id"]).first
        #
        #     if !vid_imp.blank?
        #       vid_imp.m_companion_impressions << MCompanionImpression.new(:timestamp => each_comp_imp["timestamp"])
        #     else
        #       MCompanionImpression.collection.insert(:timestamp => each_comp_imp["timestamp"], :_id => each_comp_imp["_id"], :video_impression_id => each_comp_imp["video_impression_id"])
        #     end
        #   rescue Exception => e
        #     p "rescue while comp mongodb insert"
        #   end
        # end

        ad_impressions_list_values = $redis_rtb.pipelined do
          ad_impressions_list.each do |each_impression|
            $redis_rtb.get("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}")
          end
        end

        impression_details = []
        ad_impressions_list.each_with_index do |imp, index|
          appearance_count = ad_impressions_list_values[index].to_i
          if (imp.video_impression_id.blank? && (imp.t == 1 || imp.r == 1 || appearance_count > 0 || !imp.a.blank? || imp.video.to_s == "true" || !imp.geo.blank? || !imp.device.blank? || !imp.having_related_items.blank?))
            # impression_details << ImpressionDetail.new(:impression_id => imp.id, :tagging => imp.t, :retargeting => imp.r, :pre_appearance_count => appearance_count, :device => imp.device)
            impression_details << ImpressionDetail.new(:impression_id => imp.id, :tagging => imp.t, :retargeting => imp.r, :pre_appearance_count => appearance_count, :additional_details => imp.a, :video => imp.video, :video_impression_id => imp.video_impression_id, :geo => imp.geo, :device => imp.device, :having_related_items => imp.having_related_items)
          end
        end

        ImpressionDetail.import(impression_details)


        # p "ImpressionDetail count #{impression_details.count} - #{Time.now}"
        # impression_details.each do |each_imp_det|
        #   begin
        #     ad_imp = AdImpression.where("_id" => each_imp_det.impression_id.to_s).first
        #     ad_imp.update_attributes(:pre_appearance_count => each_imp_det.pre_appearance_count) unless ad_imp.blank?
        #   rescue Exception => e
        #     p "Error while update pre appearance count"
        #   end
        # end
        #
        # p "Completed Impression Detail Update Process -  #{Time.now}"


        $redis_rtb.pipelined do
          impression_import.each do |each_impression|
            if (each_impression.advertisement_type == "advertisement" && !each_impression.temp_user_id.blank? && !each_impression.advertisement_id.blank? && each_impression.video_impression_id.blank?)
              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",2.weeks)

              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1.day)
            end
          end
        end


        #buying list update for non ad impressions

        p "Started buying list update for non ad impressions"

        redis_rtb_hash = {}
        non_ad_impressions_list.each do |impression|
          begin
            article_content = ArticleContent.find_by_sql("select sub_type,group_concat(icc.item_id) all_item_ids, ac.id from article_contents ac inner join contents c on ac.id = c.id
inner join item_contents_relations_cache icc on icc.content_id = ac.id
where url = '#{impression.hosted_site_url}' group by ac.id").first

            unless article_content.blank?
              user_id = impression.temp_user_id
              type = article_content.sub_type
              item_ids = article_content.all_item_ids.to_s rescue ""
              redis_hash = UserAccessDetail.update_buying_list(user_id, impression.hosted_site_url, type, item_ids, nil, "plannto")
              redis_rtb_hash.merge!(redis_hash) if !redis_hash.blank?
            end
          rescue Exception => e
            p "Error invalid url errors => #{impression.hosted_site_url}"
          end
        end

        # Redis Rtb update
        $redis_rtb.pipelined do
          redis_rtb_hash.each do |key, val|
            $redis_rtb.hmset(key, val.flatten)
            $redis_rtb.hincrby(key, "ap_c", 1)
            $redis_rtb.expire(key, 2.weeks)
          end
        end

        p "Completed buying list update for non ad impressions"

        p "Started Click Detail Process"

        clicks_details = []
        clicks_import.each do |each_click|
          begin
            if !each_click.t.blank? || !each_click.r.blank? || each_click.ic.to_i >0 || !each_click.a.blank?
              clicks_import = clicks_import - [each_click]
              each_click.save!
              click_detail = ClickDetail.new(:click_id => each_click.id, :tagging => each_click.t, :retargeting => each_click.r, :pre_appearance_count => each_click.ic, :additional_details => each_click.a)
              clicks_details << click_detail
            end
          rescue Exception => e
            p "Problem while creating click detail"
          end
        end

        Click.import(clicks_import)
        ClickDetail.import(clicks_details)

        clicks_import_mongo.each do |each_click_mongo|
          if !each_click_mongo["temp_user_id"].blank?
            plannto_user_detail = PUserDetail.where(:pid => each_click_mongo["temp_user_id"]).to_a.last

            if plannto_user_detail.blank?
              plannto_user_detail = PUserDetail.new(:pid => each_click_mongo["temp_user_id"])
              cookie_match = CookieMatch.where(:plannto_user_id => each_click_mongo["temp_user_id"]).select(:google_user_id).last
              plannto_user_detail.gid = cookie_match.google_user_id if !cookie_match.blank?
              plannto_user_detail.lad = Time.now
              plannto_user_detail.save!
            end
          end

          itemtype_id = nil
          #plannto user details
          if !each_click_mongo["item_id"].blank?
            itemtype = Item.where(:id => each_click_mongo["item_id"]).select(:itemtype_id).first
            itemtype_id = itemtype.itemtype_id rescue ""
          end

          if !itemtype_id.blank?
            i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
            if i_type.blank?
              plannto_user_detail.i_types << IType.new(:itemtype_id => itemtype_id, :fad => Date.today)
              i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
            end

            ci_ids = i_type.click_item_ids
            click_item_ids = click_item_ids.blank? ? [each_click_mongo["item_id"].to_i] : (click_item_ids + [each_click_mongo["item_id"].to_i])
            click_item_ids = click_item_ids.map(&:to_i).compact.uniq
            i_type.click_item_ids = click_item_ids
            i_type.lcd = Date.today
            i_type.save!
          end

          plannto_user_detail.lad = Time.now
          plannto_user_detail.save!
        end

        p "Completed Click Detail Process"

        #push to mongo
        # begin
        #   MClick.collection.insert(clicks_import_mongo)
        # rescue Exception => e
        #   p e
        #   p "Error While processing click"
        # end

        # VideoImpression.import(video_imp_import)
        #
        # $redis_rtb.pipelined do
        #   video_imp_import.each do |each_impression|
        #     if (each_impression.advertisement_type == "video_advertisement" && !each_impression.temp_user_id.blank? && !each_impression.advertisement_id.blank?)
        #       $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",1)
        #       $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",2.weeks)
        #
        #       $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1)
        #       $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1.day)
        #     end
        #   end
        # end

        $redis.ltrim("resque:queue:create_impression_and_click", add_impressions.count, -1)
        length = length - add_impressions.count
        p "*********************************** Remaining ImpressionAndClick Length - #{length} **********************************"
      end while length > 0

      # companion_impressions = MCompanionImpression.all
      $redis.set("bulk_process_add_impression_is_running", 0)
      Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc, "true")
    end
  end
=end

  def self.combine_hash(old_hash, new_hash)
    old_hash = {} if old_hash.blank?
    new_hash.each do |each_key, each_val|
      if old_hash[each_key].blank?
        old_hash[each_key] = each_val
      else
        each_val.each do |e_key, e_val|
          old_hash[each_key][e_key] = old_hash[each_key][e_key].to_i + e_val.to_i
        end
      end
    end
    old_hash
  end

  def self.combine_hash_multi_hash(old_hash, new_hash)
    old_hash = {} if old_hash.blank?
    new_hash.each do |each_key, each_val|
      if old_hash[each_key].blank?
        old_hash[each_key] = each_val
      else
        each_val.each do |e_key, e_val|
          e_key_val_hash = old_hash[each_key][e_key]
          if e_key_val_hash.blank?
            old_hash[each_key][e_key] = e_val
          else
            e_val.each do |key, val|
              e_key_val = old_hash[each_key][e_key]
              if e_key_val.blank?
                old_hash[each_key][e_key][key] = val.to_i
              else
                old_hash[each_key][e_key][key] = old_hash[each_key][e_key][key].to_i + val.to_i
              end
            end
          end
        end
      end
    end
    old_hash
  end

  def self.find_user_details(type, user_id)
    result = {}

    if type == "plannto"
      cookie_match = CookieMatch.where(:plannto_user_id => user_id).select(:google_user_id).last
      plannto_user_id = user_id
      user_id = cookie_match.google_user_id rescue "no_google_id_match"
    elsif type == "google"
      plannto_user_id = $redis_rtb.get("cm:#{user_id}")
    end

    # plannto
    redis_results = $redis.pipelined do
      $redis.hgetall("u:ac:plannto:#{plannto_user_id}")
      $redis.hgetall("u:ac:#{user_id}")
      $redis.lrange("users:last_visits:plannto:#{plannto_user_id}", 0, -1)
      $redis.lrange("users:last_visits:#{user_id}", 0, -1)
    end

    redis_rtb_results = $redis_rtb.hgetall("users:buyinglist:plannto:#{plannto_user_id}")
    redis_rtb_results_1 = $redis_rtb.hgetall("users:buyinglist:#{user_id}")

    result.merge!("u:ac:plannto:#{plannto_user_id}" => redis_results[0], "u:ac:#{user_id}" => redis_results[1], "users:last_visits:plannto:#{plannto_user_id}" => redis_results[2],
                  "users:last_visits:#{user_id}" => redis_results[3], "users:buyinglist:plannto:#{plannto_user_id}" => redis_rtb_results, "users:buyinglist:#{user_id}" => redis_rtb_results_1)

    redis_rtb_pu = $redis_rtb.pipelined do
      [21,25,26,22].each do |each_ad|
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:count")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:#{Date.today.day}")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:clicks:count")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:clicks:#{Date.today.day}")
      end
    end

    start_val = 4
    [21,25,26,22].each do |each_ad|
      result.merge!("pu:#{plannto_user_id}:#{each_ad}:count" => redis_rtb_pu[start_val-4], "pu:#{plannto_user_id}:#{each_ad}:#{Date.today.day}" => redis_rtb_pu[start_val-3], "pu:#{plannto_user_id}:#{each_ad}:clicks:count" => redis_rtb_pu[start_val-2],
                    "pu:#{plannto_user_id}:#{each_ad}:clicks:#{Date.today.day}" => redis_rtb_pu[start_val-1])
      start_val+=4
    end

    result
  end

  def self.update_include_exclude_products_from_vendors()
    if $redis.get("process_popular_vendor_products_update_is_running").to_i == 0
      $redis.set("process_popular_vendor_products_update_is_running", 1)
      $redis.expire("process_popular_vendor_products_update_is_running", 50.minutes)
      update_include_exclude_products_from_amazon()
      $redis.set("process_popular_vendor_products_update_is_running", 0)
    end
  end

  def self.update_include_exclude_products_from_vendor_flipkart()
    if $redis.get("process_popular_flipkart_products_update_is_running").to_i == 0
      $redis.set("process_popular_flipkart_products_update_is_running", 1)
      $redis.expire("process_popular_flipkart_products_update_is_running", 50.minutes)
      update_include_exclude_products_from_flipkart()
      $redis.set("process_popular_flipkart_products_update_is_running", 0)
    end
  end

  def self.update_include_exclude_products_from_amazon()
   loop_hash = {"mobiles" => {:node => 1389432031, :page_count => 4}, "tablets" => {:node => 1375458031, :page_count => 4}, "cameras" => {:node => 1389175031, :page_count => 4}, "laptops" => {:node => 1375424031, :page_count => 4}, "lenses" => {:node => 1389197031, :page_count => 3}, "televisions" => {:node => 1389396031, :page_count => 3}, "video_games" => {:node => 4069183031, :page_count => 1}}

    ad_item_id = []
    loop_hash.each do |each_key, each_val|
      begin
        item_ids = Advertisement.get_matching_item_ids(each_val[:page_count], each_val[:node], each_key)
        ad_item_id << item_ids

        if each_key == "laptops"
          lap_item_ids = item_ids.first(10).join(",")
          $redis.set("amazon_top_laptops", lap_item_ids)
        elsif each_key == "televisions"
          tv_item_ids = item_ids.first(10).join(",")
          $redis.set("amazon_top_televisions", tv_item_ids)
        elsif each_key == "mobiles"
          mobile_item_ids = item_ids.first(10).join(",")
          $redis.set("amazon_top_mobiles", mobile_item_ids)
        end

      rescue Exception => e
        p "Error while amazon api call"
      end
    end
    ad_item_id = ad_item_id.flatten
    ad_item_id = ad_item_id.join(",")

    Advertisement.update_top_product_item_ids([25, 35, 57], ad_item_id)

    exc_advertisement = Advertisement.where(:id => 26).first

    exc_advertisement.update_attributes!(:exclusive_item_ids => ad_item_id) unless exc_advertisement.blank?
  end

  def self.update_fashion_item_details_from_amazon()
    if $redis.get("popular_vendor_fashion_product_update_is_running").to_i == 0
      $redis.set("popular_vendor_fashion_product_update_is_running", 1)
      $redis.expire("popular_vendor_fashion_product_update_is_running", 50.minutes)

      loop_hash = {"saree" => {:node => 1968256031, :page_count => 10}, "salwar_suit" => {:node => 3723380031, :page_count => 10}, "women_top" => {:node => 1968543031, :page_count => 8},
                   "dress_material" => {:node => 3723377031, :page_count => 10}, "kurta" => {:node => 1968255031, :page_count => 8},
                   "legging" => {:node => 1968456031, :page_count => 2}, "dress" => {:node => 1968445031, :page_count => 8}, "handbag" => {:node => 1983346031, :page_count => 10},
                   "sunglass" => {:node => 1968401031, :page_count => 3}, "shoe" => {:node => 1983578031, :page_count => 10}, "watch" => {:node => 2563505031, :page_count => 4},
                   "external_hard_disk" => {:node => 1375395031, :page_count => 1}, "power_banks" => {:node => 976419031, :page_count => 1}, "router" => {:node => 1375439031, :page_count => 1}, "printer" => {:node => 1375443031, :page_count => 1}}


      loop_hash.each do |each_key, each_val|
        begin
          Advertisement.update_price_and_status_for_fashion_items(each_val[:page_count], each_val[:node], each_key)
        rescue Exception => e
          p "Error while amazon api call"
        end
      end

      ActiveRecord::Base.connection.execute("update itemdetails set status = 2 where site = 9882 and last_verified_date < '#{1.day.ago}'")

      $redis.set("popular_vendor_fashion_product_update_is_running", 0)
    end
  end

  def self.update_fashion_item_details_from_junglee()
    if $redis.get("popular_vendor_fashion_product_update_from_junglee_is_running").to_i == 0
      $redis.set("popular_vendor_fashion_product_update_from_junglee_is_running", 1)
      $redis.expire("popular_vendor_fashion_product_update_from_junglee_is_running", 50.minutes)

      # loop_hash = {"saree" => {:node => 824657031, :page_count => 10}, "salwar_suit" => {:node => 3723380031, :page_count => 10}, "women_top" => {:node => 1968543031, :page_count => 8},
      #              "dress_material" => {:node => 3723377031, :page_count => 10}, "kurta" => {:node => 1968255031, :page_count => 8}, "underwear" => {:node => 1968457031, :page_count => 2},
      #              "legging" => {:node => 1968456031, :page_count => 2}, "dress" => {:node => 1968445031, :page_count => 8}, "handbag" => {:node => 1983346031, :page_count => 10},
      #              "sunglass" => {:node => 1968401031, :page_count => 3}, "shoe" => {:node => 1983578031, :page_count => 10}, "watch" => {:node => 2563505031, :page_count => 4},
      #              "external_hard_disk" => {:node => 1375395031, :page_count => 1}, "power_banks" => {:node => 976419031, :page_count => 1}}

      loop_hash = {"saree" => {:node => 824657031, :page_count => 10, :items_count => 100, :product_group => "Apparel"}, "salwar_suit" => {:node => 824655031, :page_count => 10,
                  :items_count => 100, :product_group => "Apparel"}, "dress_material" => {:node => 824660031, :page_count => 10, :items_count => 100, :product_group => "Apparel"},
                   "kurta" => {:node => 824656031, :page_count => 8, :items_count => 80, :product_group => "Apparel"}, "women_top" => {:node => 792751031, :page_count => 8,
                   :items_count => 80, :product_group => "Apparel"}, "dress" => {:node => 792608031, :page_count => 8, :items_count => 80, :product_group => "Apparel"},
                   "handbag" => {:node => 805118031, :page_count => 10, :items_count => 100, :product_group => "Apparel"}, "sunglass" => {:node => 792574031, :page_count => 3,
                   :items_count => 30, :product_group => "Apparel"}, "shoe" => {:node => 805357031, :page_count => 10, :items_count => 100, :product_group => "Apparel"},
                   "watch" => {:node => 5607017031, :page_count => 4, :items_count => 40, :product_group => "Apparel"}}

      loop_hash.each do |each_key, each_val|
        begin
          Advertisement.update_price_and_status_for_fashion_items_from_junglee(each_key, each_val)
        rescue Exception => e
          p "Error while amazon api call"
        end
      end

      ActiveRecord::Base.connection.execute("update itemdetails set status = 2 where site = 73017 and last_verified_date < '#{1.day.ago}'")

      $redis.set("popular_vendor_fashion_product_update_from_junglee_is_running", 0)
    end
  end

  def self.update_price_and_status_for_fashion_items_from_junglee(key, val)
    ad_item_id = []
    node = val[:node].to_i
    page_count = val[:page_count]

    [*1..page_count].each do |each_page|
      begin
        sleep(3)

        keyword = ""
        res = Amazon::Ecs.item_search(keyword, {:response_group => 'Images,ItemAttributes,Offers', :country => 'in', :browse_node => node, :item_page => each_page, :search_index => "Marketplace", :marketplace_domain => "www.junglee.com", :sort => "salesrank"})

        items = res.items

        if ["external_hard_disk", "power_banks"].include?(key)
          items = items.first(5)
        end

        items.each do |each_item|
          begin
            url = each_item.get("DetailPageURL")
            begin
              url = URI.unescape(url)
              url = url.split("?")[0]
            rescue Exception => e
              url = url.split("%3F")[0]
            end
            id = each_item.get("ASIN").to_s.downcase rescue nil
            if id.blank?
              item_detail = Itemdetail.where(:url => url).first
            else
              item_detail = Itemdetail.where(:additional_details => id).first
              item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
            end

            if !item_detail.blank?
              begin
                #price update
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                  saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end

                  mrp_price = current_price.to_f + saved_price.to_f
                  item_detail.update_attributes!(:price => current_price, :status => status, :savepercentage => saved_percentage, :mrpprice => mrp_price, :last_verified_date => Time.now)
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end

                  item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
                else
                  item_detail.update_attributes!(:status => 2)
                end
              rescue Exception => e
                p "Error while updating itemdetail => #{item_detail.id} price"
              end

              # item = item_detail.item
              # if !item.blank?
              #   update_all_amazon_itemdetails_of_item(item, item_detail)
              #   item_id = item_detail.itemid
              #   ad_item_id << item_id
              # end
            else
              p "Not Included"
              p id
              p url

              begin
                id = each_item.get("ASIN").to_s.downcase rescue ""
                name = each_item.get_element("ItemAttributes").get("Title") rescue ""
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                current_price = nil
                status = 2
                image_url = each_item.get("LargeImage/URL") rescue nil
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                  saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end
                end

                mrp_price = current_price.to_f + saved_price.to_f

                item = Item.where(:name => key.camelize).first
                item_detail = Itemdetail.new(:itemid => item.id, :ItemName => name, :url => url, :price => current_price, :savepercentage => saved_percentage, :mrpprice => mrp_price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id, :site => "73017" , :last_verified_date => Time.now)
                item_detail.save!

                next if !item_detail.image.blank? || Rails.env == "development"

                filename = image_url.to_s.split("/").last
                filename = filename == "noimage.jpg" ? nil : filename

                filename = filename.gsub("%", "_")

                unless filename.blank?
                  name = filename.to_s.split(".")
                  name = name[0...name.size-1]
                  name = name.join(".") + ".jpeg"
                  filename = name
                end

                if !item_detail.blank? && !image_url.blank? && !filename.blank?
                  p "image----------------------------"
                  @image = item_detail.build_image
                  # tempfile = open(image_url)
                  # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
                  # avatar.original_filename = filename

                  safe_thumbnail_url = URI.encode(URI.decode(image_url))
                  extname = File.extname(safe_thumbnail_url).delete("%")

                  basename = File.basename(safe_thumbnail_url, extname).delete("%")

                  file = Tempfile.new([basename, extname])
                  file.binmode
                  open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
                    file.write data.read
                  end
                  file.rewind

                  avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
                  avatar.original_filename = filename

                  @image.avatar = avatar
                  if @image.save
                    item_detail.update_attributes(:Image => filename)
                  end
                end
              rescue Exception => e
                p "Error while creating itemdetail"
              end
            end
          rescue Exception => e
            p "skip updating itemdetails"
          end
        end
      rescue Exception => e
        p "skip amazon api call"
      end
    end
    ad_item_id
  end

  def self.update_top_product_item_ids(ad_ids, ad_item_id)
    all_item_ids = []
    ad_ids.each do |advertisement_id|
      advertisement = Advertisement.where(:id => advertisement_id).first
      if !advertisement.blank?
        content = advertisement.content

        old_item_ids_array = content.blank? ? [] : content.allitems.map(&:id)
        unless content.blank?
          new_item_ids_array = ad_item_id.split(",").map(&:to_i)
          content.update_with_items!({}, ad_item_id)
          item_ids_array = old_item_ids_array + new_item_ids_array
          item_ids_array = item_ids_array.flatten.map(&:to_i).uniq
          item_ids = item_ids_array
          all_item_ids << item_ids
        end
      end
    end
    all_item_ids = all_item_ids.flatten.uniq
    item_ids = all_item_ids.map(&:inspect).join(',')
    Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
  end

  def self.update_include_exclude_products_from_flipkart()
       loop_hash = {"mobiles" => {"sid" => "tyy,4io", "count" => 140}, "tablets" => {"sid" => "tyy,hry", "count" => 40}, "cameras" => {"sid" => "jek,p31", "count" => 100}, "laptops" => {"sid" => "6bo,b5g", "count" => 40}, "camera-accessories/lenses" => {"sid" => "jek,6l2,e9y", "count" => 40}}
        ad_item_id = []

    loop_hash.each do |key,value|
      count = value["count"]
      loop_count = count/20
      start_point = 1
      [*1..loop_count.round].each do |page_start|
        page_url = "http://www.flipkart.com/#{key}/pr?sid=#{value["sid"]}&sort=popularity&start=#{start_point}&ajax=true"
        item_ids = Advertisement.get_matching_item_ids_from_flipkart(page_url)
        ad_item_id << item_ids
        start_point+=20
      end
    end
    ad_item_id = ad_item_id.flatten
    ad_item_id.delete(0)
    ad_item_id = ad_item_id.uniq

    ad_item_id = ad_item_id.join(",")

    advertisement = Advertisement.where(:id => 10).first
    if !advertisement.blank?
      content = advertisement.content

      old_item_ids_array = content.blank? ? [] : content.allitems.map(&:id)
      unless content.blank?
        new_item_ids_array = ad_item_id.split(",")
        content.update_with_items!({}, ad_item_id)
        item_ids_array = old_item_ids_array + new_item_ids_array
        item_ids = item_ids_array.map(&:inspect).join(',')
        Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
      end
    end

    exc_advertisement = Advertisement.where(:id => 1).first

    exc_advertisement.update_attributes!(:exclusive_item_ids => ad_item_id) unless exc_advertisement.blank?
  end


  def self.get_matching_item_ids(page_count, node, each_key=nil)
    ad_item_id = []
    [*1..page_count].each do |each_page|
      begin
        sleep(3)
        res = Amazon::Ecs.item_search("", {:response_group => 'Images,ItemAttributes,Offers', :country => 'in', :browse_node => node, :item_page => each_page})

        items = res.items
        items.each do |each_item|
          begin
            url = each_item.get("DetailPageURL")
            begin
              url = URI.unescape(url)
              url = url.split("?")[0]
            rescue Exception => e
              url = url.split("%3F")[0]
            end
            id = each_item.get("ASIN").to_s.downcase rescue nil
            if id.blank?
              item_detail = Itemdetail.where(:url => url).first
            else
              item_detail = Itemdetail.where(:additional_details => id).first
              item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
            end

            if !item_detail.blank?
              begin
                #price update
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end

                  item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end

                  item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
                else
                  item_detail.update_attributes!(:status => 2)
                end
              rescue Exception => e
                p "Error while updating itemdetail => #{item_detail.id} price"
              end

              item = item_detail.item
              if !item.blank?
                update_all_amazon_itemdetails_of_item(item, item_detail)
                item_id = item_detail.itemid
                ad_item_id << item_id
              end
            else
              p "Not Included"
              p id
              p url

              next if 1 == 1 # TODO: have to fix

              begin
                id = each_item.get("ASIN").to_s.downcase rescue ""
                name = each_item.get_element("ItemAttributes").get("Title") rescue ""
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                current_price = nil
                status = 1
                image_url = each_item.get("LargeImage/URL") rescue nil
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end
                end

                item = Item.where(:name => each_key.camelize).first
                item_detail = Itemdetail.new(:itemid => item.id, :ItemName => name, :url => url, :price => current_price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id, :site => "9882" )
                item_detail.save!

                next if !item_detail.image.blank?

                filename = image_url.to_s.split("/").last
                filename = filename == "noimage.jpg" ? nil : filename

                filename = filename.gsub("%", "_")

                unless filename.blank?
                  name = filename.to_s.split(".")
                  name = name[0...name.size-1]
                  name = name.join(".") + ".jpeg"
                  filename = name
                end

                if !item_detail.blank? && !image_url.blank? && !filename.blank?
                  p "image----------------------------"
                  @image = item_detail.build_image
                  # tempfile = open(image_url)
                  # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
                  # avatar.original_filename = filename

                  safe_thumbnail_url = URI.encode(URI.decode(image_url))
                  extname = File.extname(safe_thumbnail_url).delete("%")

                  basename = File.basename(safe_thumbnail_url, extname).delete("%")

                  file = Tempfile.new([basename, extname])
                  file.binmode
                  open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
                    file.write data.read
                  end
                  file.rewind

                  avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
                  avatar.original_filename = filename

                  @image.avatar = avatar
                  if @image.save
                    item_detail.update_attributes(:Image => filename)
                  end
                end
              rescue Exception => e
                p "Error while creating itemdetail"
              end
            end
          rescue Exception => e
            p "Skip if there any error in item update"
          end
        end
      rescue Exception => e
        p "skip amazon api call error"
      end
    end
    ad_item_id
  end

  def self.update_price_and_status_for_fashion_items(page_count, node, each_key=nil)
    ad_item_id = []
    [*1..page_count].each do |each_page|
      begin
        sleep(3)

        keyword = each_key == "power_banks" ? "power bank" : ""
        res = Amazon::Ecs.item_search(keyword, {:response_group => 'Images,ItemAttributes,Offers', :country => 'in', :browse_node => node, :item_page => each_page})

        items = res.items

        if ["external_hard_disk", "power_banks"].include?(each_key)
          items = items.first(5)
        end

        items.each do |each_item|
          begin
            url = each_item.get("DetailPageURL")
            begin
              url = URI.unescape(url)
              url = url.split("?")[0]
            rescue Exception => e
              url = url.split("%3F")[0]
            end
            id = each_item.get("ASIN").to_s.downcase rescue nil
            if id.blank?
              item_detail = Itemdetail.where(:url => url).first
            else
              item_detail = Itemdetail.where(:additional_details => id).first
              item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
            end

            if !item_detail.blank?
              begin
                #price update
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                  saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end

                  mrp_price = current_price.to_f + saved_price.to_f
                  item_detail.update_attributes!(:price => current_price, :status => status, :savepercentage => saved_percentage, :mrpprice => mrp_price, :last_verified_date => Time.now)
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end

                  item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
                else
                  item_detail.update_attributes!(:status => 2)
                end
              rescue Exception => e
                p "Error while updating itemdetail => #{item_detail.id} price"
              end

              # item = item_detail.item
              # if !item.blank?
              #   update_all_amazon_itemdetails_of_item(item, item_detail)
              #   item_id = item_detail.itemid
              #   ad_item_id << item_id
              # end
            else
              p "Not Included"
              p id
              p url

              begin
                id = each_item.get("ASIN").to_s.downcase rescue ""
                name = each_item.get_element("ItemAttributes").get("Title") rescue ""
                offer_listing = each_item.get_element("Offers/Offer/OfferListing")
                offer_summary = each_item.get_element("OfferSummary")
                current_price = nil
                status = 2
                image_url = each_item.get("LargeImage/URL") rescue nil
                if !offer_listing.blank?
                  begin
                    current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  rescue Exception => e
                    current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
                  end
                  saved_price = offer_listing.get_element("AmountSaved").get("FormattedPrice").gsub("INR ", "").gsub(",", "") rescue 0
                  saved_percentage = offer_listing.get("PercentageSaved") rescue 0
                  availability_str = offer_listing.get("Availability")

                  if availability_str.blank? && !offer_summary.blank?
                    current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                    total_new = offer_summary.get("TotalNew").to_i

                    if total_new > 0
                      status = 1
                    else
                      status = 0
                    end
                  else
                    status = case availability_str
                               when /Usually dispatched.*/ || /Usually ships.*/
                                 1
                               when /Not yet released/ || /Not yet published/
                                 3
                               when /This item is not stocked or has been discontinued/
                                 4
                               when /Out of Stock/
                                 2
                               else
                                 4
                             end
                  end
                elsif !offer_summary.blank?
                  current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

                  total_new = offer_summary.get("TotalNew").to_i

                  if total_new > 0
                    status = 1
                  else
                    status = 0
                  end
                end

                mrp_price = current_price.to_f + saved_price.to_f

                item = Item.where(:name => each_key.camelize).first
                item_detail = Itemdetail.new(:itemid => item.id, :ItemName => name, :url => url, :price => current_price, :savepercentage => saved_percentage, :mrpprice => mrp_price, :status => status, :iscashondeliveryavailable => false, :isemiavailable => false, :IsError => false, :additional_details => id, :site => "9882" , :last_verified_date => Time.now)
                item_detail.save!

                next if !item_detail.image.blank?

                filename = image_url.to_s.split("/").last
                filename = filename == "noimage.jpg" ? nil : filename

                filename = filename.gsub("%", "_")

                unless filename.blank?
                  name = filename.to_s.split(".")
                  name = name[0...name.size-1]
                  name = name.join(".") + ".jpeg"
                  filename = name
                end

                if !item_detail.blank? && !image_url.blank? && !filename.blank?
                  p "image----------------------------"
                  @image = item_detail.build_image
                  # tempfile = open(image_url)
                  # avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => tempfile})
                  # avatar.original_filename = filename

                  safe_thumbnail_url = URI.encode(URI.decode(image_url))
                  extname = File.extname(safe_thumbnail_url).delete("%")

                  basename = File.basename(safe_thumbnail_url, extname).delete("%")

                  file = Tempfile.new([basename, extname])
                  file.binmode
                  open(URI.parse(safe_thumbnail_url), :allow_redirections => :all) do |data|
                    file.write data.read
                  end
                  file.rewind

                  avatar = ActionDispatch::Http::UploadedFile.new({:tempfile => file, :type => 'image/jpeg'})
                  avatar.original_filename = filename

                  @image.avatar = avatar
                  if @image.save
                    item_detail.update_attributes(:Image => filename)
                  end
                end
              rescue Exception => e
                p "Error while creating itemdetail"
              end
            end
          rescue Exception => e
            p "skip updating itemdetails"
          end
        end
      rescue Exception => e
        p "skip amazon api call"
      end
    end
    ad_item_id
  end

  def self.update_all_amazon_itemdetails_of_item(item, item_detail)
    item_details = item.itemdetails.where(:site => item_detail.site)
    item_details = item_details - [item_detail]
    item_details.each do |each_item_detail|
      begin
        asin = each_item_detail.additional_details
        next if asin.blank?

        res = res = APICache.get(asin.to_s.gsub(" ", ""), {:cache => 5.hours}) do
          Amazon::Ecs.item_lookup(asin, {:response_group => 'Images,ItemAttributes,Offers', :country => 'in'})
        end

        each_item = res.items.first

        if !each_item.blank?
          begin
            #price update
            offer_listing = each_item.get_element("Offers/Offer/OfferListing")
            offer_summary = each_item.get_element("OfferSummary")
            if !offer_listing.blank?
              begin
                current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
              rescue Exception => e
                current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""
              end
              availability_str = offer_listing.get("Availability")

              if availability_str.blank? && !offer_summary.blank?
                current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue "" if current_price.blank?

                total_new = offer_summary.get("TotalNew").to_i

                if total_new > 0
                  status = 1
                else
                  status = 0
                end
              else
                status = case availability_str
                           when /Usually dispatched.*/ || /Usually ships.*/
                             1
                           when /Not yet released/ || /Not yet published/
                             3
                           when /This item is not stocked or has been discontinued/
                             4
                           when /Out of Stock/
                             2
                           else
                             4
                         end
              end

              each_item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
            elsif !offer_summary.blank?
              current_price = offer_summary.get_element("LowestNewPrice").get("FormattedPrice").gsub("INR ", "").gsub(",","") rescue ""

              total_new = offer_summary.get("TotalNew").to_i

              if total_new > 0
                status = 1
              else
                status = 0
              end

              each_item_detail.update_attributes!(:price => current_price, :status => status, :last_verified_date => Time.now)
            else
              each_item_detail.update_attributes!(:status => 2)
            end
          rescue Exception => e
            p "Error while updating itemdetail => #{item_detail.id} price"
          end
        end
      rescue Exception => e
        p "Error processing itemdetails"
      end
      sleep(2)
    end
  end

  def self.get_matching_item_ids_from_flipkart(page_url)
    doc = Nokogiri::HTML(open(page_url))

    ad_item_id = []
    doc.css("a.fk-display-block").each do |each_link|
      url = each_link.attributes["href"].value
      url = url.to_s.split("&")[0]
      unless url.include?("flipkart.com")
        url = "http://www.flipkart.com#{url}"
      end

      id = Itemdetail.get_vendor_product_id(url.to_s)

      if id.blank?
        item_detail = Itemdetail.where(:url => url).first
      else
        item_detail = Itemdetail.where(:additional_details => id).first
        item_detail = Itemdetail.where(:url => url).first if item_detail.blank?
      end

      if !item_detail.blank?
        item_id = item_detail.itemid
        ad_item_id << item_id unless item_id.blank?
      end
    end
    ad_item_id
  end

  def self.get_alternative_list
    url = "#{Rails.root}/public/stylesheets/ads"
    types = Dir.foreach(url).to_a
    types.delete(".")
    types.delete("..")
    types = types.sort

    default_size = {"120" => "120x600", "127" => "127x100", "300" => "300x250", "468" => "468x60", "728" => "728x90"}
    sizes = []

    types.each do |type|
      new_url = url+"/"+type
      existing_sizes = Dir.foreach(new_url).to_a
      existing_sizes.delete(".")
      existing_sizes.delete("..")
      existing_sizes.each do |size|
        split_size = size.split("_")
        rel_size = split_size.count == 1 ? default_size[size] : split_size.join("x")
        sizes << rel_size
      end
    end

    sizes = sizes.compact.uniq
    sizes = sizes.sort

    alternative_list = []
    sizes.each {|each_size| alternative_list << [each_size, types]}
    alternative_list
  end

  def self.get_video_click_url(item_ids)
    item_detail_id = nil
    item_ids = item_ids.split(",")
    item_details = Itemdetail.find_by_sql("SELECT * FROM `itemdetails` INNER JOIN `items` ON `items`.`id` = `itemdetails`.`itemid` WHERE items.id in (#{item_ids.map(&:inspect).join(', ')}) and itemdetails.isError =0 and itemdetails.status in (1,3) and site = 9882")
    item_detail = item_details.first
    if !item_detail.blank?
      item_detail_id = item_detail.id
    end
    item_detail_id
  end

  def self.get_mysmartprice_matching_item_ids(page_count, url)
    total_ids = []
    [*1..page_count].each do |current_count|
      urls = []
      acutual_url = url
      if current_count !=  1
        acutual_url = url.gsub("pricelist/", "pricelist/pages/").gsub(".html", "-#{current_count}.html")
      end

      doc = Nokogiri::HTML(open(acutual_url))

      doc.css(".msplistitem .imgcont").each do |each_item|
        each_url = each_item.attributes["href"].value
        urls << each_url
      end

      items = Itemdetail.find_by_sql("SELECT additional_details from itemdetails where url in (#{urls.map(&:inspect).join(',')})")

      item_ids = items.map(&:additional_details)
      total_ids << item_ids
    end
    total_ids = total_ids.flatten
  end

  def self.update_top_item_ids_from_mysmartprice()
    loop_hash = {:mobiles => {:url => "http://www.mysmartprice.com/mobile/pricelist/mobile-price-list-in-india.html", :page_count => 6}, :tablets => {:url => "http://www.mysmartprice.com/mobile/pricelist/tablet-price-list-in-india.html", :page_count => 2}}

    total_item_ids = []

    loop_hash.each do |each_key, each_val|
      # begin
        item_ids = Advertisement.get_mysmartprice_matching_item_ids(each_val[:page_count], each_val[:url])
        total_item_ids << item_ids
      # rescue Exception => e
      #   p "Error while amazon api call"
      # end
    end
    total_item_ids = total_item_ids.flatten

    total_item_ids = total_item_ids.join(",")
    $redis.set("mysmartprice_top_products", total_item_ids)
  end

  def get_item_ids_from_ads(url)
    original_ids = []

    article_content = self.content

    if !article_content.blank?
      items = article_content.allitems
      article_items_ids = items.map(&:id)

      related_item_ids = self.related_item_ids.to_s.split(",").map(&:to_i)

      original_ids = article_items_ids - related_item_ids
    end

    return original_ids
  end

  def self.get_valid_item_ids_from_ads(valid_ad_ids)
    advertisements = Advertisement.where(:id => valid_ad_ids)
    item_ids = []

    advertisements.each do |advertisement|
      params = {:from_date => Date.today - 2.day, :to_date => Date.today, :ad_type => "advertisement", :type => "Item", :ad_id => "#{advertisement.id}"}

      start_date = params[:from_date].blank? ? Date.today.beginning_of_day : params[:from_date].to_date.beginning_of_day
      end_date = params[:to_date].blank? ? Date.today.end_of_day : params[:to_date].to_date.end_of_day

      results = AggregatedImpression.get_results_from_agg_impression(params, start_date, end_date)

      item_ids << results.keys.first(50)
    end

    item_ids = item_ids.flatten.uniq
    item_ids
  end

  def get_file_based_on_type(file_type, adv_detail)
    view_type = ""
    view_src_2 = ""
    view_ratio = 0
    file_based_type = self.images.where(:ad_size => file_type).last
    extname = file_based_type.blank? ? nil : File.extname(file_based_type.base_url)
    if extname.blank?
      view_type = "video"
      ad_video_detail = self.ad_video_detail
      if !ad_video_detail.blank?
        view_src = "#{configatron.root_image_path}static/video_ads/#{ad_video_detail.mp4}"
        view_src_2 = "#{configatron.root_image_path}static/video_ads/#{ad_video_detail.webm}"
        # view_src = "/home/sivakumar/skype/Mahindra_KUV100_TV_Ad.mp4"
        # view_src_2 = "/home/sivakumar/skype/Mahindra_KUV100_TV_Ad.webm"
      end
      if file_type == "expanded_view"
        view_ratio = adv_detail.exp_video_width.to_f/adv_detail.exp_video_height.to_f rescue 0 if !adv_detail.exp_video_width.blank? && !adv_detail.exp_video_height.blank?
      end
    else
      if ['.jpeg', '.pjpeg', '.gif', '.png', '.x-png', '.jpg'].include?(extname)
        view_type = "image"
        view_src = file_based_type.base_url rescue ""
        geo = Paperclip::Geometry.from_file(file_based_type.base_url)
        view_ratio = geo.width.to_f/geo.height
      elsif [".swf"].include?(extname)
        view_type = "flash"
        view_src = file_based_type.base_url rescue ""
      end
    end
    return view_src, view_src_2, view_type, view_ratio
  end

  def self.get_in_image_ad_from_ref_url_for_image_ads(param)
    items, tempurl, from_article_field = Item.get_items_from_url(param[:ref_url], param[:item_ids])
    # item = items.first
    item = items.flatten.select {|d| (!d.id.blank? && d.is_a?(Product))}.first
    item_id = item.id rescue ""
    item_type = item.itemtype.itemtype.to_s rescue ""
    itemtype_id = Item.get_root_level_id(item_type)
    advertisement = Advertisement.joins(:content => :item_contents_relations_cache).where("advertisements.advertisement_type='in_image_ads' and advertisements.status=1 and advertisements.end_date >= '#{Date.today}'and advertisements.ecpm !=0 and advertisements.ecpm is not null and (item_contents_relations_cache.item_id = '#{item_id}' or item_contents_relations_cache.item_id = '#{itemtype_id}')").order("ecpm desc").first
    advertisement
  end

  def self.get_ad_from_ref_url_for_image_ads(param)
    items, tempurl, from_article_field = Item.get_items_from_url(param[:ref_url], param[:item_ids])
    # item = items.first
    item = items.flatten.select {|d| (!d.id.blank? && d.is_a?(Product))}.first
    item_id = item.id rescue ""
    item_type = item.itemtype.itemtype.to_s rescue ""
    itemtype_id = Item.get_root_level_id(item_type)
    advertisement = Advertisement.joins(:content => :item_contents_relations_cache).where("advertisements.status=1 and advertisements.end_date >= '#{Date.today}'and advertisements.ecpm !=0 and advertisements.ecpm is not null and (item_contents_relations_cache.item_id = '#{item_id}' or item_contents_relations_cache.item_id = '#{itemtype_id}')").order("ecpm desc").first
    advertisement
  end

  def vendor_detail
    vendor_id = self.vendor_id
    vendor_detail = vendor_id.blank? ? nil : VendorDetail.find_by_sql("SELECT `vendor_details`.* FROM `vendor_details` WHERE `vendor_details`.`item_id` = #{vendor_id} LIMIT 1").first
    vendor_detail
  end

  def other_users
    users = []
    relationships = UserRelationship.where(:relationship_type => "Advertisement", :relationship_id => self.id)
    relationships_ids = relationships.map(&:user_id)
    if !relationships_ids.blank?
      users = User.where(:id => relationships_ids)
    end
    users
  end

  def self.get_autoscroll_status(item_ids, ad_template_type, param)
    is_remarketing = param[:r].to_i == 1 ? true : false
    return_val = false
    if (is_remarketing && item_ids.count > 1 && ad_template_type == "type_1")
      return_val = true
    end
    return_val
  end

  def self.need_to_show_fashion_pagination?(ad_template_type, suitable_ui_size)
    return_val = false
    if ad_template_type == "type_9" && ["300", "336_280", "160_600", "300_600"].include?(suitable_ui_size)
      return_val = true
    end
    return_val
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

  def convert_device_to_string
    if !self.device.blank? && self.device.is_a?(Array)
      self.device = self.device.join(",")
    end
  end

  def update_user_relationship
    if self.other_user_ids_changed?
      old_val, new_val = self.other_user_ids_change

      if !old_val.blank?
        old_val_arr = old_val.to_s.split(",").map(&:to_i)
        new_val_arr = new_val.to_s.split(",").map(&:to_i)

        skippable_user_ids = new_val_arr & old_val_arr
        removable_user_ids = old_val_arr - skippable_user_ids
        creatable_user_ids = new_val_arr - old_val_arr

        removable_user_ids.each do |each_id|
          user_relationship = UserRelationship.where(:user_id => each_id, :relationship_type => "Advertisement", :relationship_id => self.id).last
          user_relationship.destroy
        end
      else
        creatable_user_ids = self.other_user_ids.to_s.split(",").map(&:to_i)
      end

      creatable_user_ids.each do |each_id|
        user_relationship = UserRelationship.find_or_initialize_by_user_id_and_relationship_type_and_relationship_id(each_id, "Advertisement", self.id)
        if user_relationship.new_record?
          user_relationship.save
        end
      end
    end

    if !other_user_ids.blank?
      other_user_ids_arr = other_user_ids.to_s.split(",")
      users = User.where(:id => other_user_ids_arr)
      users.each do |each_user|
        user_relationship = UserRelationship.find_or_initialize_by_user_id_and_relationship_type_and_relationship_id(each_user.id, "Advertisement", self.id)
        if user_relationship.new_record?
          user_relationship.save
        end
      end
    end
  end

end

