class AddMoreColoumnsIntoShares < ActiveRecord::Migration
  def up
                 add_column :shares, :user_id, :integer
                 add_column :shares, :share_type_id, :integer
                 add_column :shares, :ip_address, :string
  end

  def down
                 remove_column :shares, :user_id
                 remove_column :shares, :share_type_id
                 remove_column :shares, :ip_address
  end
end
