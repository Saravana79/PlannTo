class TravelsController < ApplicationController

  include ItemsHelper

  def show_ads
    @ref_url = params[:ref_url] ||= ""
    url = ""

    if cookies[:plan_to_temp_user_id].blank? && cookies[:plannto_optout].blank?
      cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now}
    end
    url_params = Advertisement.url_params_process(params)

    @iframe_width, @iframe_height = params[:size].split("x")

    if (params[:ref_url] && params[:ref_url] != "" && params[:ref_url] != 'undefined')
      url = params[:ref_url]
      itemsaccess = "ref_url"
    end
    @ad = Advertisement.where("id = ? and review_status='approved'", params[:ads_id]).first

    unless @ad.blank?
      if @ad.advertisement_type == "static"
        # static ad process
        @publisher = Publisher.getpublisherfromdomain(@ad.click_url)
        @impression_id = AddImpression.save_add_impression_data("advertisement", nil, url, Time.zone.now, current_user, request.remote_ip, nil, itemsaccess,
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
              city = item.related_city
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

        @impression_id = AddImpression.save_add_impression_data("advertisement", params[:item_id], url, Time.zone.now, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id)

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

  def where_to_find_hotels

    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    @display_item_details_val = true # TODO: display item details value always true

    @show_price = params[:show_price]
    @show_offer = params[:show_offer]
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : []
    @path = params[:path]
    unless (item_ids.blank?)
      itemsaccess = "ItemId"
      if (true if Float(item_ids[0]) rescue false)
        @items = Item.where(id: item_ids)
      else
        @items = Item.where(slug: item_ids)
        @items = @items[0..15]
      end
      url = request.referer
    else

      if(params[:ref_url] && params[:ref_url] != "" && params[:ref_url] != 'undefined' )
        url = params[:ref_url]
        itemsaccess = "ref_url"
      else
        itemsaccess = "referer"
        url = request.referer
      end
      unless $redis.get("#{url}ad_or_widget_item_ids").blank?
        @items = Item.where("id in (?)", $redis.get("#{url}ad_or_widget_item_ids").split(","))
        @cities = @items.select {|s| s.is_a?(City)}
        if @cities.count != 0
          @show_by_city = true
        end
        # @items = []
      else
        unless url.nil?
          tempurl = url;
          if url.include?("?")
            tempurl = url.slice(0..(url.index('?'))).gsub(/\?/, "").strip
          end
          if url.include?("#")
            tempurl = url.slice(0..(url.index('#'))).gsub(/\#/, "").strip
          end
          @articles = ArticleContent.where(url: tempurl)

          if @articles.empty? || @articles.nil?
            #for pagination in publisher website. removing /2/
            tempstr = tempurl.split(//).last(3).join
            matchobj = tempstr.match(/^\/\d{1}\/$/)
            unless matchobj.nil?
              tempurlpage = tempurl[0..(tempurl.length-3)]
              @articles = ArticleContent.where(url: tempurlpage)
            end
          end

          unless @articles.empty?
            @items = @articles[0].allitems.select{|a| a.is_a? Hotel};
            @items = @items[0..15].reverse

            @cities = @articles[0].allitems.select{|a| a.is_a? City}
            if @cities.count != 0
              @show_by_city = true
            end

            ids = @items.collect(&:id) + @cities.collect(&:id)
            $redis.set("#{url}ad_or_widget_item_ids", ids.join(","))

          end

        end
      end
    end
    url_params = "Params = "
    if params[:item_ids]
      url_params += "item_ids-" + params[:item_ids]
    end
    if params[:path]
      url_params += ";path-" + params[:path]
    end
    if  params[:ref_url]
      url_params += ";ref_url" + params[:ref_url]
    end
    if  params[:price_full_details]
      url_params += ";more_details->" + params[:price_full_details]
    end

    @items = @items.select {|a| a.is_a?(Hotel)}
    # include pre order status if we show more details.
    unless @items.nil? || @items.empty?
      @moredetails = params[:price_full_details]
      @displaycount = 4
      if @moredetails == "true"
        @displaycount = 5
        status = "1,3".split(",")
      else
        status = "1".split(",")

      end


      @publisher = Publisher.getpublisherfromdomain(url)
      #address = Geocoder.search(request.ip)

      # get the country code for checing whether is use is from india.
      #unless address.nil? || address.empty?
      #  country = address[0].data["country_name"]  rescue ""
      #else
      country = ""
      #end

      @tempitems = []
      if (!@publisher.nil? && @publisher.id == 9 && country != "India")
        @where_to_buy_items = []
        @item = @items[0]
        itemsaccess = "othercountry"
      else
        if @show_price != "false"
          @items.each do |item|
            @item = item
            unless @publisher.nil?
              unless @publisher.vendor_ids.nil? or @publisher.vendor_ids.empty?
                vendor_ids = @publisher.vendor_ids ? @publisher.vendor_ids.split(",") : []
                exclude_vendor_ids = @publisher.exclude_vendor_ids ? @publisher.exclude_vendor_ids.split(",")  : ""
                # where_to_buy_itemstemp = @item.itemdetails.includes(:vendor).where('site not in(?) && itemdetails.status in (?)  and itemdetails.isError =?', exclude_vendor_ids,status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
                where_to_buy_itemstemp = @item.hotel_vendor_details.includes(:vendor).where('vendor_id not in (?)', exclude_vendor_ids)
                where_to_buy_items1 = where_to_buy_itemstemp.select{|a| vendor_ids.include? a.vendor_id}
                where_to_buy_items2 = where_to_buy_itemstemp.select{|a| !vendor_ids.include? a.vendor_id}
              else
                exclude_vendor_ids = @publisher.exclude_vendor_ids ? @publisher.exclude_vendor_ids.split(",")  : ""
                where_to_buy_items1 = []
                where_to_buy_items2 = @item.hotel_vendor_details.includes(:vendor).where('vendor_id not in (?)', exclude_vendor_ids)
              end
            else
              where_to_buy_items1 = []
              # where_to_buy_items2 = @item.itemdetails.includes(:vendor).where('itemdetails.status in (?)  and itemdetails.isError =?',status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
              where_to_buy_items2 = @item.hotel_vendor_details
            end
            @where_to_buy_items = where_to_buy_items1 + where_to_buy_items2
            if(@where_to_buy_items.empty?)
              @tempitems << @item
            else
              break
            end
          end
          @items = @items - @tempitems

          if(@where_to_buy_items.empty?)
            itemsaccess = "emptyitems"
          end
          @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,url,Time.zone.now,current_user,request.remote_ip,nil,itemsaccess,url_params, cookies[:plan_to_temp_user_id], nil)
        else
          @where_to_buy_items = []
          get_offers(@items.map(&:id).join(",").split(","))
          itemsaccess = "offers"
        end


      end
      @items = []
      # responses = []
      # @where_to_buy_items.group_by(&:vendor_id).each do |site, items|
      #   items.each_with_index do |item, index|
      #     @display_item_details_val
      #     if index == 0
      #       responses << {image_url: '', display_price: item.price, history_detail: "/history_details?detail_id=#{item.id}"}
      #     end
      #   end
      # end

      defatetime = Time.now.to_i

      if @items.blank? && !@cities.blank?
        @item = @cities.first
        city = @item.is_a?(City) ? @item : @item.related_city
        @related_hotels = city.hotels
        html = html = render_to_string(:template => '/travels/related_hotels', :layout => false)
      else
        html = html = render_to_string(:layout => false)
      end

      json = {"html" => html}.to_json
      callback = params[:callback]
      jsonp = callback + "(" + json + ")"
      render :text => jsonp,  :content_type => "text/javascript"
    else
      @where_to_buy_items =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.find_or_create_by_hosted_site_url_and_req_type(tempurl, "PriceComparison")
      if @impression.new_record?
        @impression.update_attributes(created_time: Time.now, updated_time: Time.now)
      else
        @impression.update_attributes(updated_time: Time.now, :count => @impression.count + 1)
      end
      #address = Geocoder.search(request.ip)
      defatetime = Time.now.to_i
      html = html = render_to_string(:layout => false)
      json = {"html" => html}.to_json
      callback = params[:callback]
      jsonp = callback + "(" + json + ")"
      render :text => jsonp,  :content_type => "text/javascript"
      # render :text => "",  :content_type => "text/javascript"
    end

  end

  def related_hotels

    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    @display_item_details_val = true # TODO: display item details value always true

    @show_price = params[:show_price]
    @show_offer = params[:show_offer]
    item_ids = params[:item_ids] ? params[:item_ids].split(",") : []
    @path = params[:path]
    unless (item_ids.blank?)
      itemsaccess = "ItemId"
      if (true if Float(item_ids[0]) rescue false)
        @items = Item.where(id: item_ids)
      else
        @items = Item.where(slug: item_ids)
        @items = @items[0..15]
      end
      url = request.referer
    end

    url_params = "Params = "
    if params[:item_ids]
      url_params += "item_ids-" + params[:item_ids]
    end
    if params[:path]
      url_params += ";path-" + params[:path]
    end
    if  params[:ref_url]
      url_params += ";ref_url" + params[:ref_url]
    end
    if  params[:price_full_details]
      url_params += ";more_details->" + params[:price_full_details]
    end

    # include pre order status if we show more details.
    unless @items.nil? || @items.empty?
      @moredetails = params[:price_full_details]
      @displaycount = 4
      if @moredetails == "true"
        @displaycount = 5
        status = "1,3".split(",")
      else
        status = "1".split(",")
      end

      @publisher = Publisher.getpublisherfromdomain(url)
      #address = Geocoder.search(request.ip)

      # get the country code for checing whether is use is from india.
      #unless address.nil? || address.empty?
      #  country = address[0].data["country_name"]  rescue ""
      #else
      country = ""
      #end

      @item = @items.first

      city = @item.is_a?(City) ? @item : @item.related_city

      @related_hotels = city.hotels

      # @tempitems = []
      # if (!@publisher.nil? && @publisher.id == 9 && country != "India")
      #   @where_to_buy_items = []
      #   @item = @items[0]
      #   itemsaccess = "othercountry"
      # else
      #     @items.each do |item|
      #       @item = item
      #       unless @publisher.nil?
      #         unless @publisher.vendor_ids.nil? or @publisher.vendor_ids.empty?
      #           vendor_ids = @publisher.vendor_ids ? @publisher.vendor_ids.split(",") : []
      #           exclude_vendor_ids = @publisher.exclude_vendor_ids ? @publisher.exclude_vendor_ids.split(",")  : ""
      #           # where_to_buy_itemstemp = @item.itemdetails.includes(:vendor).where('site not in(?) && itemdetails.status in (?)  and itemdetails.isError =?', exclude_vendor_ids,status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
      #           where_to_buy_itemstemp = @item.hotel_vendor_details.includes(:vendor).where('vendor_id not in (?)', exclude_vendor_ids)
      #           where_to_buy_items1 = where_to_buy_itemstemp.select{|a| vendor_ids.include? a.vendor_id}
      #           where_to_buy_items2 = where_to_buy_itemstemp.select{|a| !vendor_ids.include? a.vendor_id}
      #         else
      #           exclude_vendor_ids = @publisher.exclude_vendor_ids ? @publisher.exclude_vendor_ids.split(",")  : ""
      #           where_to_buy_items1 = []
      #           where_to_buy_items2 = @item.hotel_vendor_details.includes(:vendor).where('vendor_id not in (?)', exclude_vendor_ids)
      #         end
      #       else
      #         where_to_buy_items1 = []
      #         # where_to_buy_items2 = @item.itemdetails.includes(:vendor).where('itemdetails.status in (?)  and itemdetails.isError =?',status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
      #         where_to_buy_items2 = @item.hotel_vendor_details
      #       end
      #       @where_to_buy_items = where_to_buy_items1 + where_to_buy_items2
      #       if(@where_to_buy_items.empty?)
      #         @tempitems << @item
      #       else
      #         break
      #       end
      #     end
      #     @items = @items - @tempitems
      #
      #     if(@where_to_buy_items.empty?)
      #       itemsaccess = "emptyitems"
      #     end
      #     @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,url,Time.zone.now,current_user,request.remote_ip,nil,itemsaccess,url_params, cookies[:plan_to_temp_user_id], nil)
      # end

      @impression_id = AddImpression.save_add_impression_data("related_hotels",@item.id,url,Time.zone.now,current_user,request.remote_ip,nil,itemsaccess,url_params, cookies[:plan_to_temp_user_id], nil)

      # responses = []
      # @where_to_buy_items.group_by(&:vendor_id).each do |site, items|
      #   items.each_with_index do |item, index|
      #     @display_item_details_val
      #     if index == 0
      #       responses << {image_url: '', display_price: item.price, history_detail: "/history_details?detail_id=#{item.id}"}
      #     end
      #   end
      # end

      defatetime = Time.now.to_i
      html = html = render_to_string(:layout => false)
      json = {"html" => html}.to_json
      callback = params[:callback]
      jsonp = callback + "(" + json + ")"
      render :text => jsonp,  :content_type => "text/javascript"
    else
      @related_hotels =[]
      itemsaccess = "none"
      @impression = ImpressionMissing.find_or_create_by_hosted_site_url_and_req_type(url, "PriceComparison")
      if @impression.new_record?
        @impression.update_attributes(created_time: Time.now, updated_time: Time.now)
      else
        @impression.update_attributes(updated_time: Time.now, :count => @impression.count + 1)
      end
      #address = Geocoder.search(request.ip)
      defatetime = Time.now.to_i
      html = html = render_to_string(:layout => false)
      json = {"html" => html}.to_json
      callback = params[:callback]
      jsonp = callback + "(" + json + ")"
      render :text => jsonp,  :content_type => "text/javascript"
      # render :text => "",  :content_type => "text/javascript"
    end
  end

  def external_page
    cookies[:plan_to_temp_user_id] = { value: SecureRandom.hex(20), expires: 1.year.from_now } if cookies[:plan_to_temp_user_id].blank?
    @item = Item.find(params[:item_id])
    @showspec = params[:show_spec].blank? ? 0 : params[:show_spec]
    @showcompare = params[:show_compare].blank? ? 1 : params[:show_compare]
    @showreviews = params[:show_reviews].blank? ? 0 : params[:show_reviews]
    @defaulttab = params[:at].blank? ? "compare_price" : params[:at]
    @impression_id = params[:iid]
    @req = request.referer

    @where_to_buy_items = @item.hotel_vendor_details

    @impression_id = AddImpression.save_add_impression_data("pricecomparision",@item.id,request.referer,Time.zone.now,current_user,request.remote_ip,@impression_id,cookies[:plan_to_temp_user_id],nil)

    if @showspec == 1
      @item_specification_summary_lists = @item.attribute_values.includes(:attribute => :item_specification_summary_lists).where("attribute_values.item_id=? and item_specification_summary_lists.itemtype_id =?", @item.id, @item.itemtype_id).order("item_specification_summary_lists.sortorder ASC").group_by(&:proorcon)
      # @contents = Content.where(:sub_type => "Reviews")
      @item_specification_summary_lists.delete("nothing")
      @items_specification = {"Pro" => [], "Con" => []}
      @item_specification_summary_lists.each do |key, value|
        @items_specification[key[:key]] << {:values => value, description: key[:description],title: key[:title]} if key
      end
    end
    render :layout => false
  end

end
