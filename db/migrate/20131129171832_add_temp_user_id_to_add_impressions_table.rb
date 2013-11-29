class AddTempUserIdToAddImpressionsTable < ActiveRecord::Migration
  def change
  	 add_column :add_impressions, :temp_user_id, :string
  end
end
