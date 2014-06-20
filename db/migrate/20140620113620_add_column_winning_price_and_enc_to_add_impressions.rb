class AddColumnWinningPriceAndEncToAddImpressions < ActiveRecord::Migration
  def change
    add_column :add_impressions, :winning_price, :float
    add_column :add_impressions, :winning_price_enc, :text
  end
end
