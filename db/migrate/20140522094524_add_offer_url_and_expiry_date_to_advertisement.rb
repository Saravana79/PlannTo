class AddOfferUrlAndExpiryDateToAdvertisement < ActiveRecord::Migration
  def change
    add_column :advertisements, :offer_url, :string
    add_column :advertisements, :expiry_date, :date
  end
end
