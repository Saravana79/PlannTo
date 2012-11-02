class AddItemsConsideredToBuyingPlan < ActiveRecord::Migration
  def change
    add_column :buying_plans, :items_considered, :string
  end
end
