class ExternalContentsController < ApplicationController
  layout :false
  
  def show
    @content = Content.find(params[:content_id])
    HistoryDetail.create(site_url: @content.url, ip_address: request.remote_ip, redirection_time: Time.now, 
                         user_id: current_user.try(:id), plannto_location: session[:return_to])
  end

end
