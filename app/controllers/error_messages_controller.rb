class ErrorMessagesController < ApplicationController
  before_filter :authenticate_admin_user!
  layout 'product'
  
  def index
    @error_messages = ErrorMessage.order('created_at desc').paginate :page => params[:page],:per_page => 20
  end

  def show
    @error_message = ErrorMessage.find(params[:id])
  end 
end
