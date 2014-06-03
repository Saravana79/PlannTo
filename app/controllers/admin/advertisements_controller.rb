class Admin::AdvertisementsController < ApplicationController
  # before_filter :authenticate_advertiser_user!, :except => [:show_ads]
  include Admin::AdvertisementsHelper
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
    #TODO: everything is clickable is only updated for type1 have to update for type2
    impression_type, url, url_params, itemsaccess, vendor_ids, ad_id = check_and_assigns_ad_default_values()

    return static_ad_process(impression_type, url, itemsaccess, url_params) if !@ad.blank? && @ad.advertisement_type == "static"

    item_ids = params[:item_id].split(",") unless params[:item_id].blank?
    @items, itemsaccess, url = Item.get_items_by_item_ids(item_ids, url, itemsaccess, request)

    vendor_ids = Vendor.get_vendor_ids_by_publisher(url, vendor_ids) if params[:more_vendors] == "true"

    item_ids = @items.map(&:id)

    @item_details = Itemdetail.get_item_details_by_item_ids_count(item_ids, vendor_ids)

    # Default item_details based on vendor if item_details empty
    #TODO: temporary solution, have to change based on ecpm
    if @item_details.blank? && ad_id == 2 && impression_type != "advertisement_widget"
      #TODO: - Saravana - temporarily redirecting to static image ad. we need to implement this.
      @ad = Advertisement.get_ad_by_id(4).first
      return static_ad_process(impression_type, url, itemsaccess="MissingURL", url_params)
    else
      @item_details = Click.get_item_details_when_ad_not_as_widget(impression_type, @item_details, vendor_ids)
      @vendor_image_url = configatron.root_image_url + "vendor/medium/default_vendor.jpeg"
      @vendor_ad_details = vendor_ids.blank? ? {} : VendorDetail.get_vendor_ad_details(vendor_ids)
      AddImpression.add_impression_to_resque(impression_type, item_ids.first, url, current_user, request.remote_ip, nil, itemsaccess, url_params,
                                             cookies[:plan_to_temp_user_id], ad_id)
      @item_details = @item_details.uniq(&:url)
      @item_details, @sliced_item_details, @item, @items = Item.assign_template_and_item(@ad_template_type, @item_details, @items)
      @click_url = params[:click_url] =~ URI::regexp ? params[:click_url] : ""
    end

    respond_to do |format|
      format.json {
        if @item_details.blank?
          render :json => {:success => false, :html => ""}, :callback => params[:callback]
        else
          render :json => {:success => @item_details.blank? ? false : true, :html => render_to_string("admin/advertisements/show_ads.html.erb", :layout => false)}, :callback => params[:callback]
        end
      }
      format.html { render :layout => false }
    end
  end

  def check_and_assigns_ad_default_values()
    params[:more_vendors] ||= "false"
    @ad_template_type ||= "type_1"
    impression_type = params[:ad_as_widget] == "true" ? "advertisement_widget" : "advertisement"
    @vendor_ids = params[:more_vendors] == "true" ? [9861, 9882, 9874, 9880, 9856] : []
    @ref_url = params[:ref_url] ||= ""
    @iframe_width, @iframe_height = params[:size].split("*")
    @suitable_ui_size = Advertisement.process_size(@iframe_width)
    url, itemsaccess = assign_url_and_item_access(params[:ref_url], request.referer)
    @ad = Advertisement.get_ad_by_id(params[:ads_id]).first
    url_params = set_cookie_for_temp_user_and_url_params_process(params)
    vendor_ids, ad_id, @ad_template_type = assign_ad_and_vendor_id(@ad, @vendor_ids)
    return impression_type, url, url_params, itemsaccess, vendor_ids, ad_id
  end

  def static_ad_process(impression_type, url, itemsaccess, url_params)
    # static ad process
    @publisher = Publisher.getpublisherfromdomain(@ad.click_url)

    AddImpression.add_impression_to_resque(impression_type, nil, url, current_user, request.remote_ip, nil, itemsaccess, url_params, cookies[:plan_to_temp_user_id], @ad.id)

    respond_to do |format|
      format.json {
        return render :json => {:success => true, :html => render_to_string("admin/advertisements/show_static_ads.html.erb", :layout => false)}, :callback => params[:callback]
      }
      format.html { return render "show_static_ads.html.erb", :layout => false }
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
    if params[:commit] == "Clear"
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
