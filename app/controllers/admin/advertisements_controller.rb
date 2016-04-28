class Admin::AdvertisementsController < ApplicationController
  # before_filter :authenticate_publisher_user!
  # skip_before_filter :authenticate_publisher_user!, :if => proc {|c| current_user && current_user.is_admin?}
  before_filter :authenticate_user!
  before_filter :make_user_condition
  include Admin::AdvertisementsHelper
  layout "product"

  def index
    params[:date] ||= Date.today
    params[:ad_status] ||= 1

    filter_condition = "status = #{params[:ad_status]}"

    @start_date, @end_date = params[:date].to_s.split("/")
    if(current_user.id == 335)
      @start_date = "18-12-2014".to_date
      @end_date = "20-12-2014".to_date
    end
    @collections_for_dropdown = [["Today", Date.today], ['Yesterday', Date.yesterday], ['Last Week', "#{Date.today-1.week}/#{Date.today}"], ['Last month', "#{Date.today-1.month}/#{Date.today}"], ['Last 3 months', "#{Date.today-3.months}/#{Date.today}"], ['Last 6 Months', "#{Date.today-6.months}/#{Date.today}"]]
    if current_user.is_admin?
      @advertisements = Advertisement.where("#{filter_condition}").order('created_at desc').paginate(:per_page => 15, :page => params[:page])
    else
      @advertisements = Advertisement.joins(:user_relationships).where("#{@user_condition} and #{filter_condition}").order('created_at desc').paginate(:per_page => 15, :page => params[:page])
    end
    @extra_ad_details = Advertisement.get_extra_details(@advertisements, params[:date], current_user)
  end

  def new
    user_relation = UserRelationship.where(:user_id => current_user.id, :relationship_type => "Vendor").first
    vendor_id = user_relation.blank? ? "" : user_relation.relationship_id
    @vendor = Vendor.find_by_id(vendor_id)
    @advertisement = Advertisement.new(:user_id => current_user.id, :vendor_id => vendor_id, :commission => 25, :schedule_details => [*0..23].join(","), :device => "pc,mobile")
    @adv_detail = AdvDetail.new
    @advertisements = [@advertisement]
  end

  def edit
    if current_user.is_admin?
      @advertisement = Advertisement.where("advertisements.id=#{params[:id]}").first
    else
      @advertisement = Advertisement.joins(:user_relationships).where("advertisements.id=#{params[:id]} and #{@user_condition}").first
    end
    @adv_detail = @advertisement.adv_detail if !@advertisement.blank?
    @adv_detail = AdvDetail.new if @adv_detail.blank?
    @vendor = Vendor.find_by_id(@advertisement.vendor_id)
    @ad_status = @advertisement.status == 1 ? "Enable" : "Disable"

    @items = Item.where(:id => @advertisement.content.related_items.collect(&:item_id)) rescue []
    @exclusive_items = Item.where(:id => @advertisement.exclusive_item_ids.to_s.split(",")) rescue []
  end

  def show
    if current_user.is_admin?
      @advertisement = Advertisement.where("advertisements.id=#{params[:id]}").first
    else
      @advertisement = Advertisement.joins(:user_relationships).where("advertisements.id=#{params[:id]} and #{@user_condition}").first
    end
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

    params[:advertisement][:target_type] = params[:target_type].join(",")

    @advertisement = Advertisement.new(params[:advertisement])

    if !params[:content_id].blank?
      @content = AdvertisementContent.find(params[:content_id]);
      params['advertisement_content'] = {}
      params['advertisement_content']['title'] = 'advertisement'
      if @advertisement.having_related_items == true
        item_ids_for_content = params[:ad_item_id].to_s.split(",").map(&:to_i) + @advertisement.related_item_ids.to_s.split(",").map(&:to_i)
        item_ids_for_content = item_ids_for_content.uniq
        item_ids_for_content = item_ids_for_content.map(&:inspect).join(",")
        @content.update_with_items!(params['advertisement_content'], item_ids_for_content) unless @content.blank?
      else
        @content.update_with_items!(params['advertisement_content'], params[:ad_item_id]) unless @content.blank?
      end

      @advertisement.content_id = @content.id
      @advertisement.user_id = current_user.id
    else
      @content = AdvertisementContent.create(:title => "advertisement");
      @content.save_with_items!(params[:ad_item_id])
      @advertisement.content_id = @content.id
      @advertisement.user_id = current_user.id
    end

    if !current_user.blank? && current_user.is_admin?
      @advertisement.review_status = "approved"
    else
      @advertisement.review_status = "pending"
    end

    if @advertisement.save
      @advertisement.build_images(image_array, @advertisement.advertisement_type) if ["static", "flash", "display_ads", "in_image_ads"].include?(@advertisement.advertisement_type)
      if !params[:adv_detail].blank?
        @adv_detail = @advertisement.build_adv_detail(params[:adv_detail])
        @adv_detail.save
      end
      redirect_to admin_advertisements_path
    else
      @adv_detail = AdvDetail.new(params[:adv_detail])
      @advertisement.device = @advertisement.device.to_a.join(",")
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

    params[:advertisement][:target_type] = params[:target_type].join(",")
    params[:advertisement][:template_type] = "" if params[:advertisement][:advertisement_type] == "static"

    @advertisement = Advertisement.find(params[:id])
    @content = @advertisement.content
    params['advertisement_content'] = {}
    params['advertisement_content']['title'] = 'advertisement'
    if @advertisement.update_attributes(params[:advertisement])
      old_item_ids_array = @advertisement.content.blank? ? [] : @advertisement.content.allitems.map(&:id)
      unless @content.blank?
        new_item_ids_array = params[:ad_item_id].to_s.split(",").map(&:to_i) + @advertisement.related_item_ids.to_s.split(",").map(&:to_i)
        if @advertisement.having_related_items == true
          item_ids_for_content = params[:ad_item_id].to_s.split(",") + @advertisement.related_item_ids.to_s.split(",")
          item_ids_for_content = item_ids_for_content.join(",")
          @content.update_with_items!(params['advertisement_content'], item_ids_for_content)
        else
          @content.update_with_items!(params['advertisement_content'], params[:ad_item_id])
        end
        item_ids_array = old_item_ids_array + new_item_ids_array
        item_ids_array = item_ids_array.uniq
        item_ids = item_ids_array.map(&:inspect).join(',')
        Resque.enqueue(ItemUpdate, "update_item_details_with_ad_ids", Time.zone.now, item_ids)
      end
      @advertisement.build_images(image_array, @advertisement.advertisement_type) if ["static", "flash", "display_ads", "in_image_ads"].include?(@advertisement.advertisement_type)
      @adv_detail = @advertisement.adv_detail
      @adv_detail = @advertisement.build_adv_detail if @adv_detail.blank?
      @adv_detail.update_attributes(params[:adv_detail])
      redirect_to admin_advertisements_path
    else
      @adv_detail = @advertisement.adv_detail
      @advertisement.device = @advertisement.device.to_a.join(",")
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
    # @user_condition = current_user.is_admin? ? "1=1" : " user_id=#{current_user.id} "
    @user_condition = current_user.is_admin? ? "1=1" : " (advertisements.user_id=#{current_user.id} or user_relationships.user_id=#{current_user.id}) "
  end
end
