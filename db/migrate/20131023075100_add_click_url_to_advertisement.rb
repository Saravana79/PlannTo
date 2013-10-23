class AddClickUrlToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements,:click_url,:string
  end
end
