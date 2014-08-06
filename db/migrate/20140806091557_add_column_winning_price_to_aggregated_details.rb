class AddColumnWinningPriceToAggregatedDetails < ActiveRecord::Migration
  def change
    add_column :aggregated_details, :winning_price, :string
  end
end
