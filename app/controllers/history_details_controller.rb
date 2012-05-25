class HistoryDetailsController < ApplicationController

  def index
    @item_detail = Itemdetail.find(params[:detail_id])
   
    @history = HistoryDetail.new(:site_url => @item_detail.url, :ip_address => request.remote_ip, :redirection_time => Time.now)
    @history.user_id = current_user.id if user_signed_in?    
    @history.plannto_location = session[:return_to]
    @history.save
    
    redirect_to "#{@item_detail.url}"
  end
end
