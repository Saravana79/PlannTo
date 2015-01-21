class Admin::PaymentReportsController < ApplicationController
  before_filter :authenticate_publisher_user!
  skip_before_filter :authenticate_publisher_user!, :if => proc {|c| current_user && current_user.is_admin?}
  layout "product"

  def index
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date].to_date
    @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date].to_date

    if current_user.is_admin?
      @publishers = Publisher.all
      params[:publisher_id] ||= Publisher.first.id
      @publisher = Publisher.find_by_id(params[:publisher_id])
    else
      user_relationship = UserRelationship.where(:user_id => current_user.id,:relationship_type => "Publisher").first
      @publisher = Publisher.find_by_id(user_relationship.relationship_id) unless user_relationship.blank?
    end

    @payment_reports = PaymentReport.where("publisher_id=? and DATE(payment_date) >=? and DATE(payment_date) <=?", @publisher.id,@start_date.to_date,@end_date.to_date).order('payment_date desc').paginate(:per_page => 20,:page => params[:page])
  end

  def new
    @publishers = Publisher.all
    @payment_report = PaymentReport.new
  end

  def create
    @publishers = Publisher.all

    @payment_report = PaymentReport.new(params[:payment_report])

    if @payment_report.save
      redirect_to admin_payment_reports_path
    else
      render :new
    end
  end

  def edit
    @publishers = Publisher.all
    @payment_report = PaymentReport.find_by_id(params[:id])
    return redirect_to admin_payment_reports_path if @payment_report.blank?
  end

  def update
    @publishers = Publisher.all

    @payment_report = PaymentReport.find_by_id(params[:id])

    unless @payment_report.blank?
      @payment_report.update_attributes(params[:payment_report])
    end
    redirect_to admin_payment_reports_path
  end

  def destroy
    @payment_report = PaymentReport.find_by_id(params[:id])
    @payment_report.destroy
    redirect_to admin_payment_reports_path
  end

  def show
    @payment_report = PaymentReport.find_by_id(params[:id])
    @publisher = Publisher.find_by_id(@payment_report.publisher_id)
    return redirect_to admin_payment_reports_path if @payment_report.blank?

    @order_histories = @payment_report.order_histories.order('order_date desc').paginate(:per_page => 20,:page => params[:page])
    # @order_histories = OrderHistory.last(30).paginate(:per_page => 20,:page => params[:page])
    vendor_ids = OrderHistory.select("distinct vendor_ids").map(&:vendor_ids)

    @vendors =  VendorDetail.where(:item_id => vendor_ids)
  end

end
