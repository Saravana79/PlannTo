class CreateBuyingPlans < ActiveRecord::Migration
  def change
    create_table :buying_plans do |t|
      t.string :uuid, :limit => 36
      t.integer :user_id
      t.integer :itemtype_id

      t.timestamps
    end
    add_index :buying_plans, :uuid
  end
end
