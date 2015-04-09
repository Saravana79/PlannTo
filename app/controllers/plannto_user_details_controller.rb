class PlanntoUserDetailsController < ApplicationController

  def index
    unless params[:plannto_user_id].blank?
      begin
        @plannto_user_detail = PlanntoUserDetail.where(:plannto_user_id => params[:plannto_user_id]).last
        @plannto_user_detail = @plannto_user_detail.attributes
      rescue Exception => e
        @plannto_user_detail = {}
      end
    end
    render :layout => false
  end
end
