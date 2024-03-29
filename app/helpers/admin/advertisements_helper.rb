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

  def get_autoportal_links_for_ad(click_url, ad_url, item_detail=nil)
    if !item_detail.blank? && !item_detail.offer.blank?
      return_val = "<span class='offer_ad'> #{item_detail.offer} </span>"
    else
      # photo_ad_url = ad_url+"&extra_link=photos.html"
      # sales_statistics_ad_url = ad_url+"&extra_link=sales-statistics/"
      reviews_ad_url = ad_url+"&extra_link=reviews/"

      # photo_shop_now_url = click_url.blank? ? photo_ad_url : (click_url+photo_ad_url)
      # photo_link = "<a href='#{photo_shop_now_url}' id='offer_ad' class='car_extra_link_ad' target='_blank' >Photos</a>"

      fuel_type = item_detail.description.to_s.split("|")[1] rescue ""
      fuel_type_link = "<span class='offer_ad'> #{fuel_type} </span>"
      return_val = fuel_type.blank? ? "" : "#{fuel_type_link} | "

      mileage = item_detail.description.to_s.split("|")[0] rescue ""
      mileage_link = "<span class='offer_ad'> #{mileage} km/l</span>"
      return_val = mileage.blank? ? return_val : return_val+"#{mileage_link} | "

      reviews_shop_now_url = click_url.blank? ? reviews_ad_url : (click_url+reviews_ad_url)
      reviews_link = "<a href='#{reviews_shop_now_url}' id='offer_ad' class='car_extra_link_ad' target='_blank' >Reviews</a>"
      return_val = return_val+"#{reviews_link}"

      # sales_statistics_shop_now_url = click_url.blank? ? sales_statistics_ad_url : (click_url+sales_statistics_ad_url)
      # sales_statistics_link = "<a href='#{sales_statistics_shop_now_url}' id='offer_ad' class='car_extra_link_ad' target='_blank'>Sales Statistics</a>"

      # return "#{photo_link} | #{reviews_link} | #{sales_statistics_link}"
    end
    return return_val
  end

  def get_image_url(item_detail, vendor_name='')
    return_val = ''
    if !item_detail.blank? && !item_detail.Image.blank? && !vendor_name.blank?
      return_val = configatron.root_image_path + 'vendors/' + vendor_name + '/medium/' + item_detail.Image.to_s
    else
      return_val = configatron.root_image_url + item_detail.type.to_s.downcase + '/medium/' + item_detail.imageurl.to_s
    end
    return_val
  end

  def get_vendor_detail(site_id)
    if (!site_id.blank? && site_id != 0)
      vendor_detail = @vendor_ad_details.select { |v| v.item_id == site_id }.last
    else
      vendor_detail = @vendor_ad_details.select { |v| v.item_id.blank? }.last
    end
    vendor_detail
  end

  def get_image_tag(item_detail, vendor_name='', default_src='', width=100, height=100, format='medium')
    return_url = ''
    img_id = ''
    next_src = ''

    deal_item = item_detail.deal_item rescue false
    if deal_item
      return_url = item_detail.image_url
      img_id = 'item'
      next_src = ""
    elsif !item_detail.blank? && !item_detail.Image.blank? && !vendor_name.blank?
      type = item_detail.type.to_s.downcase rescue item_detail.item.type.to_s.downcase
      type = item_detail.item.type.to_s.downcase if type.blank?
      image_url = item_detail.imageurl.to_s rescue item_detail.item.imageurl.to_s
      image_url = item_detail.item.imageurl.to_s if image_url.blank?
      return_url = configatron.root_image_path + 'vendors/' + vendor_name + "/#{format}/" + item_detail.Image.to_s
      next_src = configatron.root_image_url + type + "/#{format}/" + image_url
      img_id = "item_details"
    else
      type = item_detail.type.to_s.downcase rescue item_detail.item.type.to_s.downcase
      type = item_detail.item.type.to_s.downcase if type.blank?
      image_url = item_detail.imageurl.to_s rescue item_detail.item.imageurl.to_s
      image_url = item_detail.item.imageurl.to_s if image_url.blank?
      return_url = configatron.root_image_url + type + "/#{format}/" + image_url
      next_src = ''
      img_id = 'item'
    end

    # return_url = "http://planntodev.s3.amazonaws.com/vendors/amazon/original/51kyV5FnlmL.jpeg"

    if height == 0
      height =''
    end
    # return_url = "http://ecx.images-amazon.com/images/I/51QAjlrdk7L.01_SL500_.jpg" #TODO: for testing
    "<img src='#{return_url}' alt='' default_src='#{default_src}' id='#{img_id}' class='ad_img_tag' next_src='#{next_src}' width='#{width}px' height='#{height}px'>"
  end

  def get_image_tag_using_src(image_url, width=100, height=100, format='medium')
    default_src = ''
    img_id = ''
    next_src = ''

    # return_url = "http://planntodev.s3.amazonaws.com/vendors/amazon/original/51kyV5FnlmL.jpeg"

    if height == 0
      height =''
    end
    # return_url = "http://ecx.images-amazon.com/images/I/51QAjlrdk7L.01_SL500_.jpg" #TODO: for testing
    "<img src='#{image_url}' alt='' default_src='#{default_src}' id='#{img_id}' class='ad_img_tag' next_src='#{next_src}' width='#{width}px' height='#{height}px'>"
  end

  def get_image_tag_from_item_detail_other(item_detail_other, vendor_name='', default_src='', width=100, height=100, format='medium')
    return_url = ''
    img_id = ''
    next_src = ''
    image_name = item_detail_other.image_name
    if !item_detail_other.blank? && !image_name.blank?
      return_url = "#{configatron.root_image_path}item_detail_others/ad/#{format}/#{image_name}"
      img_id = "item_details"
    else
      # return_url = configatron.root_image_url + type + "/#{format}/" + image_url
      return_url = ""
      img_id = 'item'
    end

    # return_url = "http://planntodev.s3.amazonaws.com/vendors/amazon/original/51kyV5FnlmL.jpeg"

    if height == 0
      height =''
    end
    # return_url = "http://ecx.images-amazon.com/images/I/51QAjlrdk7L.01_SL500_.jpg" #TODO: for testing
    "<img src='#{return_url}' alt='' id='#{img_id}' class='ad_img_tag' width='#{width}px' height='#{height}px'>"
  end

  def get_image_tag_from_image_name(image_name, vendor_name='', default_src='', width=100, height=100, format='medium')
    return_url = configatron.root_image_path + 'vendors/' + vendor_name + "/#{format}/" + image_name.to_s

    # return_url = "http://planntodev.s3.amazonaws.com/vendors/amazon/original/51kyV5FnlmL.jpeg"

    if height == 0
      height =''
    end
    # return_url = "http://ecx.images-amazon.com/images/I/51QAjlrdk7L.01_SL500_.jpg" #TODO: for testing
    "<img src='#{return_url}' alt='' id='item_details' class='ad_img_tag' width='#{width}px' height='#{height}px'>"
  end

  def get_vendor_image(item_detail)
    image_url = item_detail.image_url.to_s rescue "default_vendor.jpeg"
    image_url = "default_vendor.jpeg" if image_url.blank?
    src = configatron.root_image_url + "vendor" + "/medium/" + image_url
  end

  def assign_url_and_item_access(ref_url, request_referer)
    if !ref_url.blank? && ref_url != 'undefined'
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

  def set_cookie_for_temp_user_and_url_params_process(param, skip_url_params=false)
    if cookies[:plan_to_temp_user_id].blank? && cookies[:plannto_optout].blank?
      cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now}
    end

    url_params = ""
    if skip_url_params
      req_param = param.reject {|s| ["controller", "action", "ref_url", "callback", "format", "_", "click_url", "hou_dynamic_l", "protocol_type", "price_full_details", "doc_title-undefined"].include?(s.to_s)}
      url_params = Advertisement.make_url_params(req_param)
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
    end
    return status, displaycount, activate_tab
  end

  def get_ad_url(item_detail_id, impression_id, ref_url, sid, ads_id, param={}, item_detail)
    deal_item = item_detail.deal_item rescue false
    deal_item = item_detail.class == DealItem ? true : deal_item
    param[:only_layout] ||= "false"
    ad_url = ""
    red_sports_url = ""

    if deal_item == true
      item_detail_id = nil
      red_sports_url = item_detail.url
    end

    if @is_test == "true"
      ad_url = configatron.hostname + history_details_path(:detail_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :is_test => 'true', :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id], :click_url => "", :red_sports_url => red_sports_url)
    else
      ad_url = configatron.hostname + history_details_path(:detail_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id], :click_url => "", :red_sports_url => red_sports_url)
    end
    ad_url
  end

  def get_ad_url_from_detail_other(item_detail_id, impression_id, ref_url, sid, ads_id, param={})
    param[:only_layout] ||= "false"
    ad_url = ""
    if @is_test == "true"
      ad_url = configatron.hostname + history_details_path(:detail_other_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :is_test => 'true', :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id])
    else
      ad_url = configatron.hostname + history_details_path(:detail_other_id => item_detail_id, :iid => impression_id, :sid => sid, :ads_id => ads_id, :ref_url => ref_url, :t => param[:t], :r => param[:r], :ic => param[:ic], :only_layout => param[:only_layout], :a => param[:a], :video_impression_id => param[:video_impression_id])
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
