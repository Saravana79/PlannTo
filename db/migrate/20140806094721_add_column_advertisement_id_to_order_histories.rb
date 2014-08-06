class AddColumnAdvertisementIdToOrderHistories < ActiveRecord::Migration
  def change
    add_column :order_histories, :advertisement_id, :integer
  end
end
