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

  before_save :convert_device_to_string

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
    if (width == 336 && height == 280)
      return_val = "336_280"
    elsif (width == 250 && height == 250)
      return_val = "250_250"
    elsif (width == 200 && height == 200)
      return_val = "200_200"
    elsif (width == 160 && height == 600)
      return_val = "160_600"
    elsif (width <= 120)
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
                                                              plan_to_temp_user_id, ads_id, param[:wp], param[:sid], param[:t], param[:r])
      Advertisement.check_and_update_act_spent_budget_in_redis(ads_id,param[:wp])
    end
    return @impression_id
  end

  def self.make_url_params(param)
    url_params = "Params = "
    param = param.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_", "click_url"].include?(s.to_s)}
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
    url_params.each {|each_pair| new_array << each_pair.split("-")}

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
      $redis.expire("bulk_process_add_impression_is_running", 30.minutes)
      length = $redis.llen("resque:queue:create_impression_and_click")
      count = length

      begin
        add_impressions = $redis.lrange("resque:queue:create_impression_and_click", 0, 1000)

        impression_import = []
        impression_import_mongo = []
        ad_impressions_list = []
        clicks_import = []
        clicks_import_mongo = []
        video_imp_import = []
        non_ad_impressions_list = []
        add_impressions.each do |each_rec|
          count -= 1
          begin
            each_rec_arr = JSON.parse(each_rec)["args"]
            each_rec_class = each_rec_arr[0]
            each_rec_detail = each_rec_arr[1]

            if each_rec_class == "AddImpression"
              impression = AddImpression.create_new_record(each_rec_detail)

              url_params = Advertisement.reverse_make_url_params(impression.params)
              impression.device = url_params["device"]
              impression_import << impression

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
              impression_mongo["device"] = url_params["device"]
              impression_mongo["size"] = url_params["size"]
              impression_mongo["design_type"] = url_params["page_type"]
              impression_mongo["viewability"] = url_params["v"].blank? ? 101 : url_params["v"].to_i
              impression_mongo["additional_details"] = impression.a
              impression_import_mongo << impression_mongo

              if impression.advertisement_type == "advertisement"
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
                click_mongo.delete("impression_id")
                clicks_import_mongo << click_mongo
              end
            elsif each_rec_class == "VideoImpression"
              video_imp = VideoImpression.create_new_record(each_rec_detail)
              video_imp_import << video_imp
            end
          rescue Exception => e
            p "There was problem while running impressions process => #{e.backtrace}"
          end
          p "Remaining click_or_impressions Count - #{count}"
        end

        # Impression Process
        AddImpression.import(impression_import)

        #push to mongo
        # AdImpression.collection.insert(impression_import_mongo, { ordered: false })

        #TODO: Temp Fix
        begin
          #process bulk insert for mongo collection impression
          AdImpression.collection.insert(impression_import_mongo, { ordered: false })
        rescue Exception => e
          #process temp fix
          impression_import_mongo.each do |each_loop|
            begin
              AdImpression.collection.insert(each_loop)
            rescue Exception => e
              p e
            end
          end
        end

        ad_impressions_list_values = $redis_rtb.pipelined do
          ad_impressions_list.each do |each_impression|
            $redis_rtb.get("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}")
          end
        end

        impression_details = []
        ad_impressions_list.each_with_index do |imp, index|
          appearance_count = ad_impressions_list_values[index].to_i
          if (imp.t == 1 || imp.r == 1 || appearance_count > 0 || !imp.a.blank?)
            # impression_details << ImpressionDetail.new(:impression_id => imp.id, :tagging => imp.t, :retargeting => imp.r, :pre_appearance_count => appearance_count, :device => imp.device)
            impression_details << ImpressionDetail.new(:impression_id => imp.id, :tagging => imp.t, :retargeting => imp.r, :pre_appearance_count => appearance_count, :additional_details => imp.a)
          end
        end

        ImpressionDetail.import(impression_details)


        impression_details.each do |each_imp_det|
          begin
            ad_imp = AdImpression.where("_id" => each_imp_det.impression_id.to_s).last
            ad_imp.update_attributes(:pre_appearance_count => each_imp_det.pre_appearance_count) unless ad_imp.blank?
          rescue Exception => e
            p "Error while update pre appearance count"
          end
        end


        $redis_rtb.pipelined do
          impression_import.each do |each_impression|
            if (each_impression.advertisement_type == "advertisement" && !each_impression.temp_user_id.blank? && !each_impression.advertisement_id.blank?)
              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:count",2.weeks)

              $redis_rtb.incrby("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1)
              $redis_rtb.expire("pu:#{each_impression.temp_user_id}:#{each_impression.advertisement_id}:#{Date.today.day}",1.day)
            end
          end
        end


        #buying list update for non ad impressions

        redis_rtb_hash = {}
        non_ad_impressions_list.each do |impression|
          begin
            article_content = ArticleContent.find_by_sql("select sub_type,group_concat(icc.item_id) all_item_ids, ac.id from article_contents ac inner join contents c on ac.id = c.id
inner join item_contents_relations_cache icc on icc.content_id = ac.id
where url = '#{impression.hosted_site_url}' group by ac.id").last

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
          ad_impression_mon = AdImpression.where(:_id => each_click_mongo["ad_impression_id"]).last
          unless ad_impression_mon.blank?
            each_click_mongo.delete("ad_impression_id")

            m_clicks_count = ad_impression_mon.m_clicks.where(:timestamp => each_click_mongo["timestamp"]).count
            if m_clicks_count == 0
              begin
                ad_impression_mon.m_clicks << MClick.new(:timestamp => each_click_mongo["timestamp"])
              rescue Exception => e
                p "Error while push m_click"
              end
            end
          end
        end

        #push to mongo
        # begin
        #   MClick.collection.insert(clicks_import_mongo)
        # rescue Exception => e
        #   p e
        #   p "Error While processing click"
        # end

        VideoImpression.import(video_imp_import)

        $redis.ltrim("resque:queue:create_impression_and_click", add_impressions.count, -1)
        length = length - add_impressions.count
        p "*********************************** Remaining ImpressionAndClick Length - #{length} **********************************"
      end while length > 0
      $redis.set("bulk_process_add_impression_is_running", 0)
      Resque.enqueue(AggregatedDetailProcess, Time.zone.now.utc, "true")
    end
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
      [23,32,21,5,3,1,10].each do |each_ad|
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:count")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:#{Date.today.day}")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:clicks:count")
        $redis_rtb.get("pu:#{plannto_user_id}:#{each_ad}:clicks:#{Date.today.day}")
      end
    end

    start_val = 4
    [23,32,21,5,3,1,10].each do |each_ad|
      result.merge!("pu:#{plannto_user_id}:#{each_ad}:count" => redis_rtb_pu[start_val-4], "pu:#{plannto_user_id}:#{each_ad}:#{Date.today.day}" => redis_rtb_pu[start_val-3], "pu:#{plannto_user_id}:#{each_ad}:clicks:count" => redis_rtb_pu[start_val-2],
                    "pu:#{plannto_user_id}:#{each_ad}:clicks:#{Date.today.day}" => redis_rtb_pu[start_val-1])
      start_val+=4
    end

    result
  end

  def self.update_include_exclude_products_from_vendors()
    update_include_exclude_products_from_amazon()
    update_include_exclude_products_from_flipkart()
  end

  def self.update_include_exclude_products_from_amazon()
   loop_hash = {"mobiles" => {:node => 1389432031, :page_count => 12}, "tablets" => {:node => 1375458031, :page_count => 3}, "cameras" => {:node => 1389175031, :page_count => 10}, "laptops" => {:node => 1375424031, :page_count => 5}, "lenses" => {:node => 1389197031, :page_count => 6}}

    ad_item_id = []
    loop_hash.values.each do |each_val|
      begin
        item_ids = Advertisement.get_matching_item_ids(each_val[:page_count], each_val[:node])
        ad_item_id << item_ids
        sleep(2)
      rescue Exception => e
        p "Error while amazon api call"
      end
    end
    ad_item_id = ad_item_id.flatten

    ad_item_id = ad_item_id.join(",")

    advertisement = Advertisement.where(:id => 25).last
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

    exc_advertisement = Advertisement.where(:id => 26).last

    exc_advertisement.update_attributes!(:exclusive_item_ids => ad_item_id) unless exc_advertisement.blank?
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

    advertisement = Advertisement.where(:id => 10).last
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

    exc_advertisement = Advertisement.where(:id => 1).last

    exc_advertisement.update_attributes!(:exclusive_item_ids => ad_item_id) unless exc_advertisement.blank?
  end


  def self.get_matching_item_ids(page_count, node)
    ad_item_id = []
    [*1..page_count].each do |each_page|
      res = Amazon::Ecs.item_search("", {:response_group => 'Images,ItemAttributes,Offers', :country => 'in', :browse_node => node, :item_page => each_page})

      items = res.items
      items.each do |each_item|
        url = each_item.get("DetailPageURL")
        begin
          url = URI.unescape(url)
          url = url.split("?")[0]
        rescue Exception => e
          url = url.split("%3F")[0]
        end
        item_detail = Itemdetail.where(:url => url).last
        if !item_detail.blank?
          begin
            #price update
            offer_listing = each_item.get_element("Offers/Offer/OfferListing")
            if !offer_listing.blank?
              begin
                current_price = offer_listing.get_element("SalePrice").get("FormattedPrice").gsub("INR ", "").gsub(",","")
              rescue Exception => e
                current_price = offer_listing.get_element("Price").get("FormattedPrice").gsub("INR ", "").gsub(",","")
              end
              availability_str = offer_listing.get("Availability")

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

              item_detail.update_attributes!(:price => current_price, :status => status)
            else
              item_detail.update_attributes!(:status => 2)
            end
          rescue Exception => e
            p "Error while updating itemdetail => #{item_detail.id} price"
          end

          item_id = item_detail.itemid
          ad_item_id << item_id unless item_id.blank?
        end
      end
    end
    ad_item_id
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
      p url
      item_detail = Itemdetail.where(:url => url).last
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

end

