class AddTempUserIdToClicksTable < ActiveRecord::Migration
  def change
  	 add_column :clicks, :temp_user_id, :string
  end
end
