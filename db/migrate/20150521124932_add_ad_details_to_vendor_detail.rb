class AddAdDetailsToVendorDetail < ActiveRecord::Migration
  def change
    add_column :vendor_details, :action_text, :string, :default => "Shop Now"
    add_column :vendor_details, :theme_colour, :string
    add_column :vendor_details, :theme_image, :string
  end
end
