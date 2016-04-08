class AddColumnOtherUserIdsToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :other_user_ids, :string
  end
end
