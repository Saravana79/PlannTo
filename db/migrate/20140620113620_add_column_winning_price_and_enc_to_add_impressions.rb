class AddColumnWinningPriceAndEncToAddImpressions < ActiveRecord::Migration
  def change
    add_column :add_impressions, :winning_price_enc, :text
    add_column :add_impressions, :winning_price, :float
  end
end
