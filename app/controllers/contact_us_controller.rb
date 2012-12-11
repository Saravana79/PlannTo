class ContactUsController < ApplicationController
  before_filter :authenticate_user!,:only =>[:create]
  layout 'product'
  def new
    @static_page ="true"
    @contact_us = Report.new
    @type = params[:type]
  end
  
  def create
     @static_page = "true"
    @contact_us = Report.new(params[:report])
    @contact_us.reported_by = current_user.id
    if params[:type]
      @contact_us.reportable_type = params[:type]
    else
      @contact_us.reportable_type = "Contact"
    end
     @contact_us.report_from_page = session[:return_to]
    if @contact_us.save
      flash[:notice] ="Thank you for contacting us, we will get back to you soon."
      respond_to do |format|
      format.js
      format.html{ redirect_to contact_us_path}
    end
      
    else
      render :new
    end  
  end
 end
