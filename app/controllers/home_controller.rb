class HomeController < ApplicationController
  layout "product"
  def index
    redirect_to my_feeds_path if current_user
  end
 end
