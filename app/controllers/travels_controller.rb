class TravelsController < ApplicationController

  def show_ads
    @ref_url = params[:ref_url] ||= ""
    url = ""

    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
    url_params = Advertisement.url_params_process(params)

    @iframe_width, @iframe_height = params[:size].split("*")

    if (params[:ref_url] && params[:ref_url] != "" && params[:ref_url] != 'undefined')
      url = params[:ref_url]
      itemsaccess = "ref_url"
    end
    @ad = Advertisement.where("id = ?", params[:ads_id]).first

    unless @ad.blank?
      if @ad.advertisement_type == "static"
        # static ad process
        @publisher = Publisher.getpublisherfromdomain(@ad.click_url)
        @impression_id = AddImpression.save_add_impression_data("advertisement", nil, url, Time.now, current_user, request.remote_ip, nil, itemsaccess,
                                                                url_params, cookies[:plan_to_temp_user_id], @ad.id)
        render "show_static_ads", :layout => false
      elsif @ad.advertisement_type == "dynamic"
        # dynamic ad process
        # vendor_id = UserRelationship.where(:user_id => @ad.user_id, :relationship_type => "Vendor").first.relationship_id
        vendor_id = @ad.vendor_id

        @suitable_ui_size = Advertisement.process_size(@iframe_width)

        item_ids = params[:item_id].split(",")
        @item_details = []
        if item_ids.count > 1
          item_details = HotelVendorDetail.joins(:hotel).where('items.id in (?) and hotel_vendor_details.vendor_id = ?', item_ids, vendor_id).group_by { |a| a.item_id }

          item_details.each { |_, val| @item_details << val[0] }
        else
          item = Item.find_by_id(params[:item_id])

          if item.is_a?(City)
            item_ids_based_on_city = item.hotels.map(&:id)
            @item_details = HotelVendorDetail.joins(:hotel).where('items.id in (?) and hotel_vendor_details.vendor_id = ?', item_ids_based_on_city, vendor_id)
          else
            @item_details = HotelVendorDetail.joins(:hotel).where('items.id = ? and hotel_vendor_details.vendor_id = ?', params[:item_id], vendor_id)
            if (@item_details.count <= 6)
              city = item.city
              item_ids_based_on_city = city.hotels.map(&:id)
              item_ids_based_on_city = item_ids_based_on_city - [params[:item_id].to_i]
              item_details = HotelVendorDetail.joins(:hotel).where('items.id in (?) and hotel_vendor_details.vendor_id = ?', item_ids_based_on_city, vendor_id)
              required_item_details_count = 6 - @item_details.count
              item_details = item_details.first(required_item_details_count)
              @item_details << item_details
              @item_details = @item_details.flatten
            end
          end
        end

        @item_details = @item_details.first(6)

        @vendor_image_url = @item_details.first.blank? ? "" : @item_details.first.vendor.image_url
        @vendor = @item_details.first.blank? ? Vendor.new : @item_details.first.vendor
        @vendor_detail = @vendor.new_record? ? VendorDetail.new : @vendor.vendor_details.first

        @impression_id = AddImpression.save_add_impression_data("advertisement", params[:item_id], url, Time.now, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id)

        if @ad.template_type == "type_2"
          @sliced_item_details = @item_details.each_slice(2)
        end

        # TODO: Offers based on item_ids

        #@item = Item.find(item_ids[0])
        #root_id = Item.get_root_level_id(@item.itemtype.itemtype)
        #temp_item_ids = item_ids + root_id.to_s.split(",")
        #@best_deals = ArticleContent.select("distinct view_article_contents.*").joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in
        #                              (?) and view_article_contents.sub_type=? and view_article_contents.status=? and view_article_contents.field3=? and
        #                              (view_article_contents.field1=? or str_to_date(view_article_contents.field1,'%d/%m/%Y') > ? )", temp_item_ids, 'deals', 1, '0', '',
        #                              Date.today.strftime('%Y-%m-%d')).order("field4 asc, id desc")

        render :layout => false
      end
    end
  end
end
