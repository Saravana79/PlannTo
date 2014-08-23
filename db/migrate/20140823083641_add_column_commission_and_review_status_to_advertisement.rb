class AddColumnCommissionAndReviewStatusToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements, :review_status, :string
    add_column :advertisements, :commission, :float
  end
end
