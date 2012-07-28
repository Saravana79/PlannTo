class HomeController < ApplicationController
  layout "product"
  def index
    redirect_to mobiles_path if current_user
  end

end
