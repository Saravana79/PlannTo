class AddBuyingPlanToUserQuestion < ActiveRecord::Migration
  def change
    add_column :user_questions, :buying_plan_id, :integer
  end
end
