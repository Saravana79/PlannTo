class AddDeleteToBuyingPlan < ActiveRecord::Migration
  def change
    add_column :buying_plans, :deleted, :boolean
  end
end
