class Admin::FollowsController < ApplicationController
  layout "product"
   before_filter :authenticate_admin_user!
  def index
    @no_follows = Follow.count
    @follows = Follow.order('created_at desc').paginate(:per_page => 20,:page => params[:page])
  end

end
