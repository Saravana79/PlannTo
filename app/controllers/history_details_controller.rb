class HistoryDetailsController < ApplicationController

  def index
    type = params[:type].present? ? params[:type] : ""
    find_item_detail(params[:detail_id], type)
   
    @history = HistoryDetail.new(:site_url => @item_detail.url, :ip_address => request.remote_ip, :redirection_time => Time.now)
    @history.user_id = current_user.id if user_signed_in?    
    @history.plannto_location = session[:return_to]
    @history.save
    
    redirect_to "#{@item_detail.url}"
  end

  private

  def find_item_detail(detail_id, type)
    @item_detail = case type
    when "Content" then Content.find(detail_id)
    else
      Itemdetail.find(detail_id)
    end
      

  end
end
