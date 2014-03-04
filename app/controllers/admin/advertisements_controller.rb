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

   params[:type] ||= 1
   params[:size] = [120, 300, 728].include?(params[:size].to_i) ? params[:size] : 120

   item_ids = params[:item_id].split(",")
   @item_details = []
   if item_ids.count > 1
     item_details = Itemdetail.joins(:item).where('items.id in (?) and itemdetails.isError =? and site = ?', item_ids, 0, params[:vendor_id]).order('itemdetails.status asc,
                    (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc').group_by {|a| a.itemid}

     item_details.each {|_, val| @item_details << val[0]}
   else
     @item_details = Itemdetail.joins(:item).where('items.id = ? and itemdetails.isError =? and site = ?', params[:item_id], 0, params[:vendor_id]).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
   end

   @item_details = @item_details.first(6)
   @vendor_image_url = @item_details.first.vendor.image_url
   render :layout => false
 end

end
