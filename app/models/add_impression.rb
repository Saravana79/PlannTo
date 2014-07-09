class AddImpression < ActiveRecord::Base
  include ActiveUUID::UUID
  self.primary_key = "id"
  
 belongs_to :user
 belongs_to :item
 belongs_to :advertisement
 has_one :click, :foreign_key => "impression_id"

 def self.create_new_record(obj_params)
   unless obj_params.is_a?(Hash)
     obj_params = JSON.parse(obj_params)
     obj_params = obj_params.symbolize_keys
   end

   ai = AddImpression.new
   ai.id = obj_params[:imp_id]
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
   unless publisher.nil?
     ai.publisher_id = publisher.id
   end

   # save advertisement id
   ai.advertisement_id = obj_params[:ad_id]
   ai.winning_price_enc = obj_params[:winning_price_enc]
   begin
     winning_price = obj_params[:winning_price_enc].blank? ? nil : get_winning_price_value(obj_params[:winning_price_enc])
     ai.winning_price = winning_price
   rescue
     ai.winning_price = obj_params[:winning_price]
   end
   ai.created_at = obj_params[:time]
   ai.updated_at = obj_params[:time]
   ai.save
   p 444444444444444444444444444444444444444
   p Time.now
 end

  def self.get_winning_price_value(winning_price_enc)
    google_adx_encryption_key = "A3kD/CgaaDwrkYT+l8Fn3BSoCPS+nnJ2EdJc+EwOa/E="
    google_adx_integrity_key = "Qbpmbfcih39Z64lodZXJ5Gn8ABQgUS09wMrGRk6rEaM="
    enc_data = adx_websafe_pad(winning_price_enc)
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
      p j.unpack("H*").first.to_i(16).to_s(10)
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

  def self.add_impression_to_resque(impression_type, item_id, request_referer, user, remote_ip, impressionid, itemsaccess, url_params, plan_to_temp_user_id, ad_id, winning_price_enc)
    impression_id = SecureRandom.uuid
    impression_params = {:imp_id => impression_id, :type => impression_type, :itemid => item_id, :request_referer => request_referer, :time => Time.zone.now, :user => user.blank? ? nil : user.id, :remote_ip => remote_ip, :impression_id => impressionid, :itemaccess => itemsaccess,
                         :params => url_params, :temp_user_id => plan_to_temp_user_id, :ad_id => ad_id, :winning_price => 0.0, :winning_price_enc => winning_price_enc}.to_json
    # Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)
    AddImpression.create_new_record(impression_params)
    return impression_id
  end

end

