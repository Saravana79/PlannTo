class AddCoulmnOrdersToItemAdDetailsAndContentAdDetails < ActiveRecord::Migration
  def change
    add_column :item_ad_details, :orders, :integer
    add_column :content_ad_details, :orders, :integer
  end
end
