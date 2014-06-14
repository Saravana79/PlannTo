class Advertisement < ActiveRecord::Base
   validates_presence_of :name
   validates_presence_of :click_url
   has_attached_file :upload_image, 
                     :styles => {  :medium => "120x120>", :thumb => "24x24>" },
                     :storage => :s3,
                     :bucket => ENV['planntonew'],
                     :s3_credentials => "config/s3.yml",
                     :path => "images/advertisements/:id/:style/:filename",
                     :url  => ":s3_sg_url"

   has_many :images, as: :imageable, dependent: :destroy
   has_many :add_impressions
   belongs_to :content
   belongs_to :user
   belongs_to :vendor

   after_save :update_click_url_based_on_vendor
   after_save :update_redis_with_advertisement

   scope :get_ad_by_id, lambda {|id| where("id = ?", id)}

   #validate :file_dimensions

   def self.url_params_process(param)
     url_params = "Params = "
     param = param.reject {|s| ["controller", "action"].include?(s)}
     keys = param.keys
     values = param.values

     [*0...keys.count].each do |each_val|
       url_params = url_params + "#{keys[each_val]}-#{values[each_val]};"
     end
     return url_params
   end

   def self.process_size(width)
     width = width.to_i
     if (width <= 120)
       return_val = 120
     elsif (width <= 130)
       return_val = 127
     elsif (width < 350)
       return_val = 300
     elsif (width < 750)
       return_val = 728
     else
       return_val = 120
     end
     return return_val
   end

   def build_images(image_array)
     image_array.each do |image|
       image = self.images.build(image)
       if Image.file_dimensions(image)
         image.save
       end
     end
   end

   def self.calculate_ecpm
     advertisements = Advertisement.where("bid = 'CPC'")
     count = 0
     advertisements.each do |advertisement|
       clicks_count = Click.joins(:add_impression).where("add_impressions.advertisement_id = ?", advertisement.id).count
       impressions_count = advertisement.add_impressions.count

       if (clicks_count != 0 &&  impressions_count != 0)
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

     ad_status = false
     if status.to_i == 1
       if ((!start_date.blank? && start_date.to_date >= Date.today) && (!end_date.blank? && end_date.to_date <= Date.today))
         ad_status = true
       end
     end

     Resque.enqueue(UpdateRedis, "advertisments:#{id}", "type", advertisement_type, "vendor_id", vendor_id, "ecpm", ecpm, "dailybudget", budget, "click_url", formatted_click_url, "enabled", ad_status)

     # Enqueue ItemUpdate with created advertisement item_ids
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

   def self.update_rtb_budget(log)
     advertisements = Advertisement.where("status = ? and start_date <= ? and end_date >= ?",1,Date.today, Date.today)
     advertisements.each do |advertisement|
       account_name = "PlannToAccount_#{advertisement.id}"
       hourly_budget = advertisement.get_hourly_budget()
       uri = URI("#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}")
       account = Net::HTTP.get(uri)

       if account == "\"couldn't get account\"\n"
         uri_to_create = URI("#{configatron.rtbkit_hostname}/v1/accounts?accountName=#{account_name}&accountType=budget")
         response = Net::HTTP.post_form(uri_to_create, {})
         raise advertisement unless response.code == "200"
         puts "Response #{response.code}: Created New Account #{accout_name}"
         account = response.body
       end

       account_hash = JSON.parse(account)

       existing_budget = account_hash["budgetIncreases"].blank? ? 0 : account_hash["budgetIncreases"]["USD/1M"]
       budget_now = existing_budget + (hourly_budget * 1000000)
       payload = {"USD/1M" => budget_now}.to_json
       post_budget(account_name, payload)
     end
   end

   def get_hourly_budget
     hourly_budget = self.budget.to_f / 24
   end

   def self.post_budget(account_name, payload)
     p uri_post = URI("#{configatron.rtbkit_hostname}/v1/accounts/#{account_name}/budget")
     req = Net::HTTP::Post.new(uri_post.path, initheader = {'Content-Type' =>'application/json'})
     req.body = payload
     response = Net::HTTP.new(uri_post.host, uri_post.port).start {|http| http.request(req) }
     puts "Response #{response.code} #{response.message}:
          #{response.body}"
     raise advertisement unless response.code == "200"
   end

   private

   def file_dimensions
         hieght_width = self.ad_size.split("*")
         dimensions = Paperclip::Geometry.from_file(upload_image.queued_for_write[:original].path)
         logger.info "===========================================#{dimensions.width} +++++++++++++++#{dimensions.height}"
         if dimensions.width.to_i.to_s != hieght_width[0] || dimensions.height.to_i.to_s != hieght_width[1]
            errors.add :file, "Width must be #{hieght_width[0]}px and height must be #{hieght_width[1]}px"
         end
   end

end
