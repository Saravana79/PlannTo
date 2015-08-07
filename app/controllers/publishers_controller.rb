class PublishersController < ApplicationController
  before_filter :authenticate_user!
  layout "product"

  def index
    @publisher = current_user.publisher
  end
end
