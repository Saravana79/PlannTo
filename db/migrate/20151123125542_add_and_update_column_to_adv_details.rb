class AddAndUpdateColumnToAdvDetails < ActiveRecord::Migration
  def change
    remove_column :adv_details, :only_flash
    add_column :adv_details, :need_close_btn, :boolean, :default => true
    add_column :adv_details, :expand_on, :string
  end
end
