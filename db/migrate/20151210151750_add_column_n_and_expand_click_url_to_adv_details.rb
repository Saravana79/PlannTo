class AddColumnNAndExpandClickUrlToAdvDetails < ActiveRecord::Migration
  def change
    add_column :adv_details, :nv_click_url, :string
    add_column :adv_details, :ev_click_url, :string
  end
end
