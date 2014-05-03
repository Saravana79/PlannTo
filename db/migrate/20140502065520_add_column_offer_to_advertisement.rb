class AddColumnOfferToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements, :offer, :string
  end
end
