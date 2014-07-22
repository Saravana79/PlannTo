class AddColumnAvgWinningPriceToSidAdDetails < ActiveRecord::Migration
  def change
    add_column :sid_ad_details, :avg_winning_price, :float
  end
end
