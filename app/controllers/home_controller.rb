class HomeController < ApplicationController
  layout "root_page"
  def index
    redirect_to my_feeds_path if current_user
  end
  
  def terms_conditions
  
  end
  
  def privacy_policy
  
  end
  
  def about_us
  
  end
 end
