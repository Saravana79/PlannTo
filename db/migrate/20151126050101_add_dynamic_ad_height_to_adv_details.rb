class AddDynamicAdHeightToAdvDetails < ActiveRecord::Migration
  def change
    add_column :adv_details, :dynamic_ad_height, :integer
  end
end
