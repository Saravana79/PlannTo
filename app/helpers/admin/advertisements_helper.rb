module Admin::AdvertisementsHelper
  def get_offer_for_ad(ad, item_detail, vendor_default_text, text_size=80, shop_now_url=nil)
    if !ad.blank? && !ad.expiry_date.blank? && ad.expiry_date > Date.today && !ad.offer.blank?
      url = ad.offer_url.blank? ? shop_now_url : ad.offer_url
      return_val = "<a href='#{url}' id='offer_ad' target='_blank' >#{truncate_without_dot(ad.offer, text_size)}</a>"
    else
      return_val = item_detail.offer.blank? ? truncate_without_dot(vendor_default_text.to_s, text_size) : truncate_without_dot(item_detail.offer.to_s, text_size)
    end
    return_val
  end

  def get_image_url(item_detail, vendor_name='')
    return_val = ''
    if !item_detail.blank? && !item_detail.Image.blank? && !vendor_name.blank?
      return_val = configatron.root_image_path + 'vendors/' + vendor_name + '/medium/' + item_detail.Image.to_s
    else
      return_val = configatron.root_image_url + item_detail.type.downcase + '/medium/' + item_detail.imageurl.to_s
    end
    return_val
  end

  def get_image_tag(item_detail, vendor_name='', default_src='', width=100, height=100, format='medium')
    return_url = ''
    img_id = ''
    next_src = ''
    if !item_detail.blank? && !item_detail.Image.blank? && !vendor_name.blank?
      return_url = configatron.root_image_path + 'vendors/' + vendor_name + "/#{format}/" + item_detail.Image.to_s
      next_src = configatron.root_image_url + item_detail.type.downcase + "/#{format}/" + item_detail.imageurl.to_s
      img_id = "item_details"
    else
      return_url = configatron.root_image_url + item_detail.type.downcase + "/#{format}/" + item_detail.imageurl.to_s
      next_src = ''
      img_id = 'item'
    end

    if height == 0
      height =''
    end

    "<img src='#{return_url}' alt='' default_src='#{default_src}' id='#{img_id}' class='ad_img_tag' next_src='#{next_src}' width='#{width}px' height='#{height}px'>"
  end

  def assign_url_and_item_access(ref_url, request_referer)
    if (ref_url && ref_url != "" && ref_url != 'undefined')
      return ref_url, "ref_url"
    else
      return request_referer, "referer"
    end
  end

  def assign_ad_and_vendor_id(ad, vendor_ids)
    ad_template_type = "type_1"
    if !ad.blank?
      vendor_ids = vendor_ids.blank? ? [ad.vendor_id] : vendor_ids
      ad_id = ad.id
      ad_template_type = ad.template_type unless ad.template_type.blank?
    else
      vendor_ids = vendor_ids
      ad_id = ""
      ad_template_type = "type_1"
    end
    return vendor_ids, ad_id, ad_template_type
  end

  def set_cookie_for_temp_user_and_url_params_process(param)
    if cookies[:plan_to_temp_user_id].blank? && cookies[:plannto_optout].blank?
      cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now}
    end

    url_params = Advertisement.make_url_params(param)
    return url_params
  end

  def set_status_and_display_count(moredetails, activate_tab)
    displaycount = 4
    if moredetails == "true"
      displaycount = 5
      status = "1,3".split(",")
    else
      status = "1".split(",")
    end
    return status, displaycount, activate_tab
  end

  def get_ad_url(item_detail_id, impression_id, ref_url, sid, ads_id, param={})
    param[:only_layout] ||= "false"
    ad_url = ""
    if @is_test == "true"
      ad_url = configatron.hostname + history_details_path(:detail_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :is_test => 'true', :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id])
    else
      ad_url = configatron.hostname + history_details_path(:detail_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id])
    end
    ad_url
  end


  def get_static_ad_url(click_url, impression_id, ref_url, sid, ads_id, param={})
    param[:only_layout] ||= "false"
    ad_url = ""
    if @is_test == "true"
      ad_url = configatron.hostname + history_details_path(:iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :is_test => 'true', :only_layout => param[:only_layout], :a => param[:a])
    else
      ad_url = configatron.hostname + history_details_path(:iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :only_layout => param[:only_layout], :a => param[:a])
    end
    ad_url
  end

  def get_ad_status(ad_id)
    ad_status = $redis_rtb.hget("advertisments:#{ad_id}", "status")
    return_val = ad_status == "enabled" ? "Enable" : "Disable"
    return_val
  end
end
