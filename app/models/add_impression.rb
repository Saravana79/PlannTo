class AddImpression < ActiveRecord::Base
  require 'base64'
  require 'facets/string/xor'
  require 'openssl'

  attr_accessor :t, :r, :device, :a, :video, :video_impression_id, :geo, :having_related_items

  include ActiveUUID::UUID
  self.primary_key = "id"
  
 belongs_to :user
 belongs_to :item
 belongs_to :advertisement
 has_one :order_history, :foreign_key => :impression_id
 has_one :click, :foreign_key => "impression_id"

 def self.create_new_record(obj_params)
   unless obj_params.is_a?(Hash)
     obj_params = JSON.parse(obj_params)
   end
   obj_params = obj_params.symbolize_keys

   ai = AddImpression.new
   ai.id = obj_params[:imp_id]
   p "Creating Impression - #{ai.id}"
   ai.impression_id = obj_params[:impression_id]
   ai.advertisement_type = obj_params[:type]
   ai.item_id = obj_params[:itemid]
   ai.hosted_site_url = obj_params[:request_referer]
   ai.impression_time = obj_params[:time]
   unless obj_params[:user].nil?
     ai.user_id = obj_params[:user]
   end
   ai.temp_user_id = obj_params[:temp_user_id]
   ai.ip_address = obj_params[:remote_ip]
   ai.itemsaccess = obj_params[:itemsaccess]
   ai.params = obj_params[:params]
   publisher = Publisher.getpublisherfromdomain(obj_params[:request_referer])
   if !publisher.blank?
     ai.publisher_id = publisher.id
   else
     ai.publisher_id = obj_params[:publisher]
   end

   # save advertisement id
   if obj_params[:ad_id].blank?
     ad_id = obj_params[:advertisement_id]
   else
     ad_id = obj_params[:ad_id]
   end
   ai.advertisement_id = ad_id
   # ai.winning_price_enc = obj_params[:winning_price_enc] # removed from db
   begin
     winning_price = obj_params[:winning_price_enc].blank? ? 0.0 : get_winning_price_value(obj_params[:winning_price_enc])
     ai.winning_price = winning_price.to_f
   rescue
     ai.winning_price = 0.0
   end
   ai.sid = obj_params[:sid]
   ai.created_at = obj_params[:time]
   ai.updated_at = obj_params[:time]

   ai.t = obj_params[:t].to_i
   ai.r = obj_params[:r].to_i
   ai.a = obj_params[:a].to_s
   ai.device = obj_params[:device].to_s
   ai.video = obj_params[:video].to_s
   ai.video_impression_id = obj_params[:video_impression_id].to_s
   ai.geo = obj_params[:geo]
   ai.having_related_items = ai.advertisement.having_related_items rescue false

   return ai
 end

  def self.push_to_redis(user_id, advertisement_id)
    $redis_rtb.pipelined do
      $redis_rtb.incrby("pu:#{user_id}:#{advertisement_id}:count",1)
      $redis_rtb.expire("pu:#{user_id}:#{advertisement_id}:count",2.weeks)

      $redis_rtb.incrby("pu:#{user_id}:#{advertisement_id}:#{Date.today.day}",1)
      $redis_rtb.expire("pu:#{user_id}:#{advertisement_id}:#{Date.today.day}",1.day)
    end
  end

  def self.get_winning_price_value(winning_price_enc)
    google_adx_encryption_key = "\x03\x79\x03\xfc\x28\x1a\x68\x3c\x2b\x91\x84\xfe\x97\xc1\x67\xdc\x14\xa8\x08\xf4\xbe\x9e\x72\x76\x11\xd2\x5c\xf8\x4c\x0e\x6b\xf1"
    google_adx_integrity_key  = "\x41\xba\x66\x6d\xf7\x22\x87\x7f\x59\xeb\x89\x68\x75\x95\xc9\xe4\x69\xfc\x00\x14\x20\x51\x2d\x3d\xc0\xca\xc6\x46\x4e\xab\x11\xa3"
    enc_data = adx_websafe_pad(winning_price_enc)
    #
    # google_adx_encryption_key = "\xb0\x8c\x70\xcf\xbc\xb0\xeb\x6c\xab\x7e\x82\xc6\xb7\x5d\xa5\x20\x72\xae\x62\xb2\xbf\x4b\x99\x0b\xb8\x0a\x48\xd8\x14\x1e\xec\x07"
    # google_adx_integrity_key  = "\xbf\x77\xec\x55\xc3\x01\x30\xc1\xd8\xcd\x18\x62\xed\x2a\x4c\xd2\xc7\x6a\xc3\x3b\xc0\xc4\xce\x8a\x3d\x3b\xbd\x3a\xd5\x68\x77\x92"
    # enc_data = adx_websafe_pad('SjpvRwAB4kB7jEpgW5IA8p73ew9ic6VZpFsPnA')

    adx_decrypt(enc_data,google_adx_encryption_key,google_adx_integrity_key)
  end

  def self.adx_websafe_pad(str)
    pad = "";
    if str.length%4== 2
      pad = "==";
    elsif str.length%4 == 3
      pad = "=";
    end
    str = str+pad
    str.tr('-_','+/')
  end

  def self.adx_decrypt(encrypted_data,google_adx_encryption_key,google_adx_integrity_key)
    enc_key = google_adx_encryption_key
    ciphertext = Base64.urlsafe_decode64(encrypted_data)
    plaintext_length = ciphertext.length-16-4
    iv = ciphertext[0..15]
    ciphertext_end = 16+plaintext_length
    add_iv_counter_byte = true
    ciphertext_begin=16
    plaintext_begin=0
    plaintext = Array.new
    while ciphertext_begin<ciphertext_end do
      digest = OpenSSL::Digest.new('sha1')
      pad = OpenSSL::HMAC.digest(digest, enc_key, iv)
      i = 0
      while (i<20 and ciphertext_begin != ciphertext_end) do
        plaintext[plaintext_begin] = ciphertext[ciphertext_begin] ^ pad[i]
        plaintext_begin+=1
        ciphertext_begin+=1
        i+=1
      end

      unless add_iv_counter_byte
        index = iv.length - 1;
        iv[index] = (iv[index].ord+1).chr
        add_iv_counter_byte = iv[index] == 0;
      end
      if add_iv_counter_byte
        add_iv_counter_byte = false
        iv += "\x0"
      end
    end
    #Integrity Checks
    sig = ciphertext[24..27]
    int_key = google_adx_integrity_key
    digest = OpenSSL::Digest.new('sha1')
    conf_sig = OpenSSL::HMAC.digest(digest, int_key, plaintext.join('')+ciphertext[0..15])
    if conf_sig[0..3]==sig
      j =plaintext.join("")
      j.unpack("H*").first.to_i(16).to_s(10)
    else
      p "Signature mismatch"
    end
  end

 def self.save_add_impression_data(type,itemid,request_referer,time,user,remote_ip,impression_id,itemsaccess=nil,params=nil, temp_user_id, ad_id)
  # ai = AddImpression.find_by_impression_id_and_advertisement_type_and_item_id_and_hosted_site_url_and_temp_user_id(impression_id, type, itemid, request_referer, temp_user_id )
  # unless ai
      ai = AddImpression.new
      ai.impression_id = impression_id
      ai.advertisement_type = type
      ai.item_id = itemid
      ai.hosted_site_url = request_referer
      ai.impression_time = time
      unless user.nil?
         ai.user_id = user.id
      end
      ai.temp_user_id = temp_user_id
      ai.ip_address = remote_ip
      ai.itemsaccess = itemsaccess
      ai.params = params
      publisher = Publisher.getpublisherfromdomain(request_referer)
      unless publisher.nil?
         ai.publisher_id = publisher.id
      end

      # save advertisement id
      ai.advertisement_id = ad_id
      ai.save 
  # end
   return ai.id
 end


 def self.chart_data(ad_id, start_date, end_date)
   if start_date.nil?
     start_date = 2.weeks.ago
   end

   if end_date.nil?
     end_date = Date.today
   end

   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s

     kliks = count(
         :group => 'month(impression_time)',
         :conditions => { :advertisement_id => ad_id, :impression_time => range }
     )

     # CREATE JSON DATA FOR EACH MONTH
     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
       {
           impression_time: date.strftime("%b, %Y"),
           clicks: kliks[date.month] || 0
       }
     end


   else

     kliks = count(
         :group => 'date(impression_time)',
         :conditions => { :advertisement_id => ad_id, :impression_time => range }
     )

     #WORKS FINE DATA FOR EACH DAY
     (start_date.to_date..end_date.to_date).map do |date|
       {
           impression_time: date.strftime("%F"),
           clicks: kliks[date] || 0
       }
     end
   end
 end

 def self.chart_data_widgets(publisher_id, start_date, end_date, types)
   if start_date.nil?
     start_date = 2.weeks.ago
   end

   if end_date.nil?
     end_date = Date.today
   end

   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s

     kliks = count(
         :group => 'month(impression_time)',
         :conditions => { :publisher_id => publisher_id, :impression_time => range, :advertisement_type => types }
     )

     # CREATE JSON DATA FOR EACH MONTH
     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
       {
           impression_time: date.strftime("%b, %Y"),
           clicks: kliks[date.month] || 0
       }
     end


   else

     kliks = count(
         :group => 'date(impression_time)',
         :conditions => { :publisher_id => publisher_id, :impression_time => range, :advertisement_type => types }
     )

     #WORKS FINE DATA FOR EACH DAY
     (start_date.to_date..end_date.to_date).map do |date|
       {
           impression_time: date.strftime("%F"),
           clicks: kliks[date] || 0
       }
     end
   end
 end

  def self.add_impression_to_resque(impression_type, item_id, request_referer, user_id, remote_ip, impressionid, itemsaccess, url_params, plan_to_temp_user_id, ad_id, winning_price_enc, sid=nil, t=nil, r=nil, a=nil, video=false, video_impression_id=nil)
    impression_id = SecureRandom.uuid
    impression_params = {:imp_id => impression_id, :type => impression_type, :itemid => item_id, :request_referer => request_referer, :time => Time.zone.now.utc, :user => nil, :remote_ip => remote_ip, :impression_id => impressionid, :itemaccess => itemsaccess,
                         :params => url_params, :temp_user_id => plan_to_temp_user_id, :ad_id => ad_id, :winning_price => nil, :winning_price_enc => winning_price_enc, :sid => sid, :t => t, :r => r, :a => a, :video => video, :video_impression_id => video_impression_id}.to_json
    Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)
    # AddImpression.create_new_record(impression_params)
    return impression_id
  end

end