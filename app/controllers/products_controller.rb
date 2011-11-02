class ProductsController < ApplicationController
  def index

  end

  def show
    product = Item.find_by_id(params[:id])
    @product_attributes = product.item_attributes.select("value, name, unit_of_measure, category_name").group_by(&:category_name)
  end
end
