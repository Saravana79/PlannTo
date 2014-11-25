class ChangeColumnClickIdToClickDetails < ActiveRecord::Migration
  def up
    change_column :click_details, :click_id, :integer
  end

  def down
    change_column :click_details, :click_id, :uuid
  end
end
