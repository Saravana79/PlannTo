module Admin::AdvertisementsHelper
  def get_offer_for_ad(ad, item_detail, vendor_default_text, text_size=80, shop_now_url=nil)
    if !ad.blank? && !ad.expiry_date.blank? && ad.expiry_date <= Date.today && !ad.offer.blank?
      url = ad.offer_url.blank? ? shop_now_url : ad.offer_url
      return_val = "<a href='#{url}' >#{truncate_without_dot(ad.offer, text_size)}</a>"
    else
      return_val = item_detail.offer.blank? ? vendor_default_text.to_s : item_detail.offer.to_s
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
end
