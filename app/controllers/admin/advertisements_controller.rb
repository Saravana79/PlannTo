class Admin::AdvertisementsController < ApplicationController
 before_filter :authenticate_advertiser_user!, :except => [:show_ads]
 layout "product"
 
   def index
     @advertisements = Advertisement.where(:status => 1).order('created_at desc').paginate(:per_page => 10,:page => params[:page])
  end

  def new
    @advertisement = Advertisement.new 
    @advertisements = [@advertisement]
  end

  def edit
    @advertisement = Advertisement.find(params[:id])
    @items = Item.where("id in (#{@advertisement.content.related_items.collect(&:item_id).join(',')})")
  end

  def show
    @advertisement = Advertisement.find(params[:id])
  end

  def create
    images = params[:advertisement].delete(:upload_image)
    logger.info "===================================#{params[:advertisement][:ad_size]}"

    add_size = params[:advertisement].delete(:ad_size)
    image_array = []
    images.each_with_index do |image, i|
      image_array << {upload_image: image, ad_size: add_size[i]}
    end
    flag = true
    @advertisements = []
    Advertisement.transaction do
      image_array.each do |image|
        @advertisement = Advertisement.new(params[:advertisement].merge!(image))
        @content = AdvertisementContent.create(:title => "advertisement");
        @content.save_with_items!(params['ad_item_id'])
        @advertisement.content_id = @content.id
        if !@advertisement.save
          flag = false
        
        end
      @advertisements << @advertisement

      end
      raise ActiveRecord::Rollback unless flag
    end
      if flag
        redirect_to admin_advertisements_path
      else
        
        render :new
      end    
  end
  
  def update
    @advertisement = Advertisement.find(params[:id])
     @content = @advertisement.content
     params['advertisement_content'] = {}
     params['advertisement_content']['title'] = 'advertisement'
     @content.update_with_items!(params['advertisement_content'], params[:ad_item_id]) 
    if @advertisement.update_attributes(params[:advertisement])
      redirect_to admin_advertisements_path
    else
      render :edit
    end
  end
  
  def destroy
   @advertisement = Advertisement.find(params[:id])
   @advertisement.update_attribute('status',3)
   redirect_to admin_advertisements_path
  end

 def show_ads
   #@page_width = params[:size].split("*")[0]
   #@page_height = params[:size].split("*")[1]

   @vendor = Vendor.where(:id => params[:vendor_id]).first
   item_ids = params[:item_id].split(",")
   @item_details = []
   if item_ids.count > 1
     item_ids.each do |each_item|
       item = Item.where(:id => each_item).first
       item_detail = item.itemdetails.includes(:vendor).where('itemdetails.isError =? and site = ?', 0, params[:vendor_id]).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc').first
       @item_details << item_detail unless item_detail.blank?
     end
   else
     @item = Item.where(:id => params[:item_id]).first
     @item_details = @item.itemdetails.includes(:vendor).where('itemdetails.isError =? and site = ?', 0, params[:vendor_id]).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
   end

   render :layout => false
 end

end
