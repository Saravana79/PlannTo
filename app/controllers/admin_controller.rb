class AdminController < ApplicationController

  def index
    search_type = Product.search_type(params[:type])
    @items = Sunspot.search(search_type) do
      keywords params[:name], :fields => :name
      order_by :class, :desc
      paginate(:page => 1, :per_page => 15)
    end
  end
end
