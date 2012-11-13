class ContactUsController < ApplicationController
  before_filter :authenticate_user!,:only =>[:create]
  layout 'product'
  def new
    @static_page ="true"
    @contact_us = Report.new
  end
  
  def create
     @static_page = "true"
    @contact_us = Report.new(params[:report])
    @contact_us.reported_by = current_user.id
    @contact_us.reportable_type = "Contact"
    if @contact_us.save
      flash[:notice] ="Thank you for contacting us, we will get back to you soon."
      redirect_to contact_us_path
    else
      render :new
    end  
  end
 end
