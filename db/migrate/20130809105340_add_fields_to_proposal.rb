class AddFieldsToProposal < ActiveRecord::Migration
  def change
    add_column :proposals,:user_id,:integer
    add_column :proposals,:vendor_id,:integer
  end
end
