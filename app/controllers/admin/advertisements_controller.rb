class Admin::AdvertisementsController < ApplicationController
  # before_filter :authenticate_advertiser_user!, :except => [:show_ads]
  layout "product"

  def index
    @advertisements = Advertisement.where(:status => 1).order('created_at desc').paginate(:per_page => 10, :page => params[:page])
  end

  def new
    user_relation = UserRelationship.where(:user_id => current_user.id, :relationship_type => "Vendor").first
    vendor_id = user_relation.blank? ? "" : user_relation.relationship_id
    @vendor = Vendor.find_by_id(vendor_id)
    @advertisement = Advertisement.new(:user_id => current_user.id, :vendor_id => vendor_id)
    @advertisements = [@advertisement]
  end

  def edit
    @advertisement = Advertisement.find(params[:id])
    @vendor = Vendor.find_by_id(@advertisement.vendor_id)


    @items = Item.where("id in ('#{@advertisement.content.related_items.collect(&:item_id).join(',')}')")
  end

  def show
    @advertisement = Advertisement.find(params[:id])
  end

  def create
    images = params.delete(:avatar)

    add_size = params.delete(:ad_size)

    image_array = []
    unless images.blank?
      images.each_with_index do |image, i|
        image_array << {avatar: image, ad_size: add_size[i]}
      end
    end


    logger.info "===================================#{params[:ad_size]}"

    params[:advertisement][:template_type] = "" if params[:advertisement][:advertisement_type] == "static"

    @advertisement = Advertisement.new(params[:advertisement])
    @content = AdvertisementContent.create(:title => "advertisement");
    @content.save_with_items!(params['ad_item_id'])
    @advertisement.content_id = @content.id
    @advertisement.user_id = current_user.id
    if @advertisement.save
      @advertisement.build_images(image_array) if @advertisement.advertisement_type == "static"
      redirect_to admin_advertisements_path
    else
      render :new
    end
end

def update
  images = params.delete(:avatar)

  add_size = params.delete(:ad_size)

  image_array = []

  unless images.blank?
    images.each_with_index do |image, i|
      image_array << {avatar: image, ad_size: add_size[i]}
    end
  end


  params[:advertisement][:template_type] = "" if params[:advertisement][:advertisement_type] == "static"

  @advertisement = Advertisement.find(params[:id])
  @content = @advertisement.content
  params['advertisement_content'] = {}
  params['advertisement_content']['title'] = 'advertisement'
  @content.update_with_items!(params['advertisement_content'], params[:ad_item_id])
  if @advertisement.update_attributes(params[:advertisement])
    @advertisement.build_images(image_array) if @advertisement.advertisement_type == "static"
    redirect_to admin_advertisements_path
  else
    render :edit
  end
end

def destroy
  @advertisement = Advertisement.find(params[:id])
  @advertisement.update_attribute('status', 3)
  redirect_to admin_advertisements_path
end

def show_ads
  params[:more_vendors] ||= "false"
  @ad_template_type ||= "type_1"

  impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"

  @vendor_ids =[]
  @vendor_ids = [9861, 9882, 9874, 9880, 9856] if params[:more_vendors] == "true"
  #TODO: everything is clickable is only updated for type1 have to update for type2
  @ref_url = params[:ref_url] ||= ""
  url = ""

  cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
  url_params = Advertisement.url_params_process(params)

  @iframe_width, @iframe_height = params[:size].split("*")

  if(params[:ref_url] && params[:ref_url] != "" && params[:ref_url] != 'undefined' )
    url = params[:ref_url]
    itemsaccess = "ref_url"
  else
    itemsaccess = "referer"
    url = request.referer
  end

  @ad = Advertisement.get_ad_by_id(params[:ads_id]).first


    if !@ad.blank? && @ad.advertisement_type == "static"
      # static ad process
      @publisher = Publisher.getpublisherfromdomain(@ad.click_url)
      # @impression_id = AddImpression.save_add_impression_data("advertisement", nil, url, Time.zone.now, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id)

      @impression_id = SecureRandom.uuid
      impression_params =  {:imp_id => @impression_id, :type => impression_type, :itemid => nil, :request_referer => url, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
       :params => url_params, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => @ad.id}.to_json
      Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)

      # return render "show_static_ads.html.erb", :layout => false
      respond_to do |format|
        format.json {
          return render :json => {:success => true, :html => render_to_string("admin/advertisements/show_static_ads.html.erb", :layout => false)}, :callback => params[:callback]
        }
        format.html { return render "show_static_ads.html.erb", :layout => false}
      end
    end

    # if (@ad.blank? || (!@ad.blank? & @ad.advertisement_type == "dynamic"))
      # dynamic ad process
      # vendor_id = UserRelationship.where(:user_id => @ad.user_id, :relationship_type => "Vendor").first.relationship_id


    if !@ad.blank?
      vendor_ids = @vendor_ids.blank? ? [@ad.vendor_id] : @vendor_ids
      ad_id = @ad.id
      @ad_template_type = @ad.template_type unless @ad.template_type.blank?
    else
      vendor_ids = @vendor_ids
      ad_id = ""
      @ad_template_type = "type_1"
    end

      # vendor_ids = @vendor_ids.blank? ? [@ad.vendor_id] : @vendor_ids

      @suitable_ui_size = Advertisement.process_size(@iframe_width)

      item_ids = params[:item_id].split(",") unless params[:item_id].blank?

      @items = []
      unless (item_ids.blank?)
        itemsaccess = "ItemId"
        # if (true if Float(item_ids[0]) rescue false)
        # @items = Item.where(id: item_ids)
        @items = Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{item_ids.map(&:inspect).join(',')}) order by i.ectr DESC limit 6")
        # else
        #   @items = Item.where(slug: item_ids)
        #   @items = @items[0..15]
        # end
        url = request.referer
      else
        unless $redis.get("#{url}ad_item_ids").blank?
          # @items = Item.where("id in (?)", $redis.get("#{url}ad_item_ids").split(","))
          redis_item_ids = $redis.get("#{url}ad_item_ids").split(",")
          @items = Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{redis_item_ids.map(&:inspect).join(',')}) order by i.ectr DESC limit 15")
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
              @items = @articles[0].allitems.select{|a| a.is_a? Product};
              # @items = @items[0..15].reverse
              article_items_ids = @items.map(&:id)
              new_items = article_items_ids.blank? ? nil : Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{article_items_ids.map(&:inspect).join(',')}) order by i.ectr DESC limit 15")

              if !new_items.blank?
                @items = new_items
              end
              $redis.set("#{url}ad_item_ids", @items.collect(&:id).join(",")) unless @items.blank?
            end
          end
        end
      end

      item_ids = @items.map(&:id)

      @item_details = []
      if item_ids.count > 1
        @item_details = Itemdetail.get_item_details_by_item_ids(item_ids, vendor_ids).group_by {|each_rec| each_rec.itemid}

        # item_details.each { |_, val| @item_details << val }
      elsif item_ids.count > 0
        @item_details = Itemdetail.get_item_details(item_ids.first, vendor_ids).group_by {|each_rec| each_rec.itemid}
      end

      @item_details = @item_details.blank? ? [] : Itemdetail.get_sort_by_vendor(@item_details)
      @item_details = @item_details.flatten

      @item_details = @item_details.uniq
      @item_details = @item_details.uniq(&:url)
      # @item_details = @item_details.first(6)

      # Default item_details based on vendor if item_details empty
      #TODO: temporary solution, have to change based on ecpm
      if @item_details.blank? && ad_id == 2 && impression_type != "advertisement_widget"

         #### - Saravana - temporarily redirecting to static image ad. we need to implement this.

          @ad = Advertisement.get_ad_by_id(4).first
          itemaccess = "MissingURL"
          @impression_id = SecureRandom.uuid
          impression_params =  {:imp_id => @impression_id, :type => impression_type, :itemid => nil, :request_referer => url, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
           :params => url_params, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => @ad.id}.to_json
          Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)

          # render "show_static_ads.html.erb", :layout => false
          respond_to do |format|
            format.json {
              return render :json => {:success => true, :html => render_to_string("admin/advertisements/show_static_ads.html.erb", :layout => false)}, :callback => params[:callback]
            }
            format.html { return render "show_static_ads.html.erb", :layout => false}
          end

      else
         if impression_type != "advertisement_widget" && @item_details.blank?
            unless $redis.get("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}").blank?
              @item_details = Itemdetail.get_item_details($redis.get("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}"), vendor_ids)
            end
            if @item_details.blank?
              clicks = Click.where("vendor_id in (?)", vendor_ids).order("created_at desc").limit(10)
              clicks.each do |click|
                @item_details = Itemdetail.get_item_details(click.item_id, vendor_ids)
                unless @item_details.blank?
                  $redis.set("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}", click.item_id)
                  $redis.expire("default_item_id_for_vendor_#{vendor_ids.sort.join("_")}", 86400)
                  break
                end
              end
            end
         end
         @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"

         @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
          # @impression_id = AddImpression.save_add_impression_data("advertisement", item_ids.join(','), url, Time.zone.now, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id)

          @impression_id = SecureRandom.uuid
          impression_params =  {:imp_id => @impression_id, :type => impression_type, :itemid => item_ids.first, :request_referer => url, :time => Time.zone.now, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => nil, :itemaccess => itemsaccess,
                                                                   :params => url_params, :temp_user_id => cookies[:plan_to_temp_user_id], :ad_id => ad_id}.to_json
          Resque.enqueue(CreateImpressionAndClick, 'AddImpression', impression_params)

          @item_details = @item_details.uniq(&:url)

          if @ad_template_type == "type_2"
            @item_details = @item_details.first(12)
            @sliced_item_details = @item_details.each_slice(2)
          else
            @item_details = @item_details.first(6)
          end

          # TODO: Offers based on item_ids

          #@item = Item.find(item_ids[0])
          #root_id = Item.get_root_level_id(@item.itemtype.itemtype)
          #temp_item_ids = item_ids + root_id.to_s.split(",")
          #@best_deals = ArticleContent.select("distinct view_article_contents.*").joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in
          #                              (?) and view_article_contents.sub_type=? and view_article_contents.status=? and view_article_contents.field3=? and
          #                              (view_article_contents.field1=? or str_to_date(view_article_contents.field1,'%d/%m/%Y') > ? )", temp_item_ids, 'deals', 1, '0', '',
          #                              Date.today.strftime('%Y-%m-%d')).order("field4 asc, id desc")

          @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""

         # assign items
         if !@items.blank?
           @item = @items.first
         elsif @items.blank? && !@item_details.blank?
           list_item_ids = @item_details.map(&:itemid).uniq

           @items = Item.where("id in (?)", list_item_ids)
           @item = @items.first
         end
          # render :layout => false
      end

      respond_to do |format|
        format.json {
          if @item_details.blank?
            render :json => {:success => false, :html => ""}, :callback => params[:callback]
          else
            render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string("admin/advertisements/show_ads.html.erb", :layout => false)}, :callback => params[:callback]
          end
        }
        format.html {render :layout => false}
      end

end

  def delete_ad_image
    image = Image.find_by_id(params[:id])
    image_id = image.id
    image.destroy
    render :js => "$('##{image_id}').remove(); alert('Image deleted successfully');"
  end

  def test_ads
    @app_url = Rails.env == "production" ? "http://www.plannto.com" : "http://localhost:3000"
    if params[:commit] == "clear"
      params[:item_id] = ""
      params[:ref_url] = "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"
      params[:ads_id] = 2
      params[:more_vendors] = true
      params[:page_type] ||= "small_screen"
    else
      params[:item_id] ||= "" #5414,1469
      params[:ref_url] ||= "http://gadgetstouse.com/full-reviews/gionee-elife-e6-review/11205"
      params[:ads_id] ||= 2
      params[:more_vendors] ||= true
      params[:page_type] ||= "small_screen"
    end
    render :layout => false
  end

  def search_widget_via_iframe
    @app_url = params[:app_url]
    render :layout => false
  end

  def ad_via_iframe
    render :layout => false
  end

end
