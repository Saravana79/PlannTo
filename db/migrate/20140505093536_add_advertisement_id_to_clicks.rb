class AddAdvertisementIdToClicks < ActiveRecord::Migration
  def change
    add_column :clicks, :advertisement_id, :integer
  end
end
