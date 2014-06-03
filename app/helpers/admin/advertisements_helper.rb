module Admin::AdvertisementsHelper
  def get_offer_for_ad(ad, item_detail, vendor_default_text, text_size=80, shop_now_url=nil)
    if !ad.blank? && !ad.expiry_date.blank? && ad.expiry_date <= Date.today && !ad.offer.blank?
      url = ad.offer_url.blank? ? shop_now_url : ad.offer_url
      return_val = "<a href='#{url}' >#{truncate_without_dot(ad.offer, text_size)}</a>"
    else
      return_val = item_detail.offer.blank? ? truncate_without_dot(vendor_default_text.to_s, text_size) : truncate_without_dot(item_detail.offer.to_s, text_size)
    end
    return_val
  end

  def get_image_url(item_detail, vendor_name='')
    return_val = ''
    if !item_detail.blank? && !item_detail.Image.blank?
      return_val = configatron.root_image_path + 'vendors/' + vendor_name + '/medium/' + item_detail.Image.to_s
    else
      return_val = configatron.root_image_url + item_detail.type.downcase + '/medium/' + item_detail.imageurl.to_s
    end
    return_val
  end

  def assign_url_and_item_access(ref_url, request_referer)
    if (ref_url && ref_url != "" && ref_url != 'undefined')
      return ref_url, "ref_url"
    else
      return request_referer, "referer"
    end
  end

  def assign_ad_and_vendor_id(ad, vendor_ids)
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
    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?

    url_params = "Params = "
    param = param.reject {|s| ["controller", "action"].include?(s)}
    keys = param.keys
    values = param.values

    [*0...keys.count].each do |each_val|
      url_params = url_params + "#{keys[each_val]}-#{values[each_val]};"
    end
    return url_params
  end

  def set_status_and_display_count(moredetails, activate_tab)
    displaycount = 4
    if moredetails == "true"
      displaycount = 5
      status = "1,3".split(",")
    else
      status = "1".split(",")
      activate_tab = false
    end
    return status, displaycount, activate_tab
  end
end
