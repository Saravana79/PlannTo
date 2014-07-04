class Admin::AdvertisementsController < ApplicationController
  # before_filter :authenticate_advertiser_user!, :except => [:show_ads]
  before_filter :authenticate_publisher_user!
  skip_before_filter :authenticate_publisher_user!, :if => proc {|c| current_user && current_user.is_admin?}
  before_filter :make_user_condition
  include Admin::AdvertisementsHelper
  layout "product"

  def index
    @advertisements = Advertisement.where("status=1 #{@user_condition}").order('created_at desc').paginate(:per_page => 10, :page => params[:page])
  end

  def new
    user_relation = UserRelationship.where(:user_id => current_user.id, :relationship_type => "Vendor").first
    vendor_id = user_relation.blank? ? "" : user_relation.relationship_id
    @vendor = Vendor.find_by_id(vendor_id)
    @advertisement = Advertisement.new(:user_id => current_user.id, :vendor_id => vendor_id)
    @advertisements = [@advertisement]
  end

  def edit
    @advertisement = Advertisement.where("id=#{params[:id]} #{@user_condition}").first
    @vendor = Vendor.find_by_id(@advertisement.vendor_id)


    @items = Item.where(:id => @advertisement.content.related_items.collect(&:item_id)) rescue []
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

    if @advertisement.save
      @advertisement.build_images(image_array) if @advertisement.advertisement_type == "static"
      redirect_to admin_advertisements_path
    else
      @items = Item.where(:id => @content.related_items.collect(&:item_id)) rescue []
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
      @content.update_with_items!(params['advertisement_content'], params[:ad_item_id]) unless @content.blank?
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

  private

  def make_user_condition
    @user_condition = current_user.is_admin? ? "" : " AND user_id=#{current_user.id}"
  end
end
