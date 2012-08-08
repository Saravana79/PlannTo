class ErrorMessagesController < ApplicationController
  before_filter :authenticate_admin_user!
  
  def index
    @error_messages = ErrorMessage.order('created_at desc').all.paginate :page => params[:page],:per_page => 10
  end
  def show
    @error_message = ErrorMessage.find(params[:id])
  end 
end
