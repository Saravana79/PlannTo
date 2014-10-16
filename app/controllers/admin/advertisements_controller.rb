class Admin::AdvertisementsController < ApplicationController
  before_filter :authenticate_publisher_user!
  skip_before_filter :authenticate_publisher_user!, :if => proc {|c| current_user && current_user.is_admin?}
  before_filter :make_user_condition
  include Admin::AdvertisementsHelper
  layout "product"

  def index
    params[:date] ||= Date.today
    @start_date, @end_date = params[:date].to_s.split("/")
    @collections_for_dropdown = [["Today", Date.today], ['Yesterday', Date.yesterday], ['Last Week', "#{Date.today-1.week}/#{Date.today}"], ['Last month', "#{Date.today-1.month}/#{Date.today}"], ['Last 3 months', "#{Date.today-3.months}/#{Date.today}"], ['Last 6 Months', "#{Date.today-6.months}/#{Date.today}"]]
    @advertisements = Advertisement.where("#{@user_condition}").order('created_at desc').paginate(:per_page => 15, :page => params[:page])
    @extra_ad_details = Advertisement.get_extra_details(@advertisements, params[:date])
  end

  def new
    user_relation = UserRelationship.where(:user_id => current_user.id, :relationship_type => "Vendor").first
    vendor_id = user_relation.blank? ? "" : user_relation.relationship_id
    @vendor = Vendor.find_by_id(vendor_id)
    @advertisement = Advertisement.new(:user_id => current_user.id, :vendor_id => vendor_id, :commission => 25)
    @advertisements = [@advertisement]
  end

  def edit
    @advertisement = Advertisement.where("id=#{params[:id]} #{@user_condition}").first
    @vendor = Vendor.find_by_id(@advertisement.vendor_id)
    @ad_status = @advertisement.status == 1 ? "Enable" : "Disable"

    @items = Item.where(:id => @advertisement.content.related_items.collect(&:item_id)) rescue []
    @exclusive_items = Item.where(:id => @advertisement.exclusive_item_ids.to_s.split(",")) rescue []
  end

  def show
    @advertisement = Advertisement.where("id=#{params[:id]} #{@user_condition}").first
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

    if !params[:content_id].blank?
      @content = AdvertisementContent.find(params[:content_id]);
      params['advertisement_content'] = {}
      params['advertisement_content']['title'] = 'advertisement'
      @content.update_with_items!(params['advertisement_content'], params[:ad_item_id]) unless @content.blank?
      @advertisement.content_id = @content.id
      @advertisement.user_id = current_user.id
    else
      @content = AdvertisementContent.create(:title => "advertisement");
      @content.save_with_items!(params[:ad_item_id])
      @advertisement.content_id = @content.id
      @advertisement.user_id = current_user.id
    end

    @advertisement.review_status = "pending"

    if @advertisement.save
      @advertisement.build_images(image_array, @advertisement.advertisement_type) if @advertisement.advertisement_type == "static" || @advertisement.advertisement_type == "flash"
      redirect_to admin_advertisements_path
    else
      @items = Item.where(:id => @content.related_items.collect(&:item_id)) rescue []
      @exclusive_items = Item.where(:id => params[:advertisement][:exclusive_item_ids].to_s.split(",")) rescue []
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
    if @advertisement.update_attributes(params[:advertisement])
      old_item_ids_array = @advertisement.content.blank? ? [] : @advertisement.content.allitems.map(&:id)
      unless @content.blank?
        new_item_ids_array = params[:ad_item_id].to_s.split(",")
        @content.update_with_items!(params['advertisement_content'], params[:ad_item_id])
        item_ids_array = old_item_ids_array + new_item_ids_array
        item_ids = item_ids_array.map(&:inspect).join(',')
        Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
      end
      @advertisement.build_images(image_array, @advertisement.advertisement_type) if @advertisement.advertisement_type == "static" || @advertisement.advertisement_type == "flash"
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

  def change_ad_status
    status = params[:status]
    advertisement = Advertisement.where(:id => params[:ad_id]).first
    if (["Enable","Disable"].include?(status))
      ad_status = status == "Enable" ? 1 : 0
      advertisement.update_attributes!(:status => ad_status)
      # ad_status = status == "Enable" ? "enabled" : (status == "Disable" ? "disabled" : "paused")
      # $redis_rtb.hset("advertisments:#{params[:ad_id]}", "status", ad_status)
      redirect_to admin_advertisements_path
    elsif status == "Delete"
      begin
        advertisement.destroy
      rescue
        advertisement.delete
      end
      $redis_rtb.del("advertisments:#{params[:ad_id]}")
      redirect_to admin_advertisements_path
    end
  end

  def review
    @advertisement = Advertisement.find(params[:advertisement_id])
  end

  def approved
    @advertisement = Advertisement.find(params[:id])
    @advertisement.update_attributes!(:review_status => "approved")
    flash[:notice] = "Advertisement is approved"
    redirect_to admin_advertisements_path
  end

  def denied
    @advertisement = Advertisement.find(params[:id])
    @advertisement.update_attributes!(:review_status => "denied")
    flash[:notice] = "Advertisement is denied"
    redirect_to admin_advertisements_path
  end

  private

  def make_user_condition
    @user_condition = current_user.is_admin? ? "" : " user_id=#{current_user.id} "
  end
end
