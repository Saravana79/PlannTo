class Admin::AdvertisementsController < ApplicationController
 before_filter :authenticate_advertiser_user!
 layout "product"
 
   def index
     @advertisements = Advertisement.where(:status => 1).order('created_at desc').paginate(:per_page => 10,:page => params[:page])
  end

  def new
    @advertisement = Advertisement.new 
  end

  def edit
    @advertisement = Advertisement.find(params[:id])
    @items = Item.where("id in (#{@advertisement.content.related_items.collect(&:item_id).join(',')})")
  end

  def show
    @advertisement = Advertisement.find(params[:id])
  end

  def create
    @advertisement = Advertisement.new(params[:advertisement])
    @content = AdvertisementContent.create(:title => "advertisement");
    @content.save_with_items!(params['ad_item_id'])
    @advertisement.content_id = @content.id
    if @advertisement.save
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
 
end
