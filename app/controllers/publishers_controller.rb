class PublishersController < ApplicationController
  before_filter :authenticate_user!
  layout "product"

  def index

  end
end
