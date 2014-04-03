class Admin::AdvertisementsController < ApplicationController
  before_filter :authenticate_advertiser_user!, :except => [:show_ads]
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
      vendor_id = UserRelationship.where(:user_id => @ad.user_id, :relationship_type => "Vendor").first.relationship_id

      @suitable_ui_size = Advertisement.process_size(@iframe_width)

      item_ids = params[:item_id].split(",")
      @item_details = []
      if item_ids.count > 1
        item_details = Itemdetail.joins(:item).where('items.id in (?) and itemdetails.isError =? and site = ?', item_ids, 0, vendor_id).order('itemdetails.status asc,
                         (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc').group_by { |a| a.itemid }

        item_details.each { |_, val| @item_details << val[0] }
      else
        @item_details = Itemdetail.joins(:item).where('items.id = ? and itemdetails.isError =? and site = ?', params[:item_id], 0, vendor_id).order('itemdetails.status asc,
                          (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
      end

      @item_details = @item_details.first(6)
      @vendor_image_url = @item_details.first.vendor.image_url
      @vendor = @item_details.first.vendor
      @vendor_detail = @vendor.vendor_details.first
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

  def delete_ad_image
    image = Image.find_by_id(params[:id])
    image_id = image.id
    image.destroy
    render :js => "$('##{image_id}').remove(); alert('Image deleted successfully');"
  end

end
