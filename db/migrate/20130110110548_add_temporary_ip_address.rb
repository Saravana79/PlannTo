class AddTemporaryIpAddress < ActiveRecord::Migration
  def up
    add_column :buying_plans,:temporary_buying_plan_ip,:string
  end

  def down
    remove_column :buying_plans,:temporary_buying_plan_ip,:string
  end
end
