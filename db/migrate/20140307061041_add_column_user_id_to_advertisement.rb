class AddColumnUserIdToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements, :user_id, :integer
    add_column :advertisements, :vendor_id, :integer
  end
end
