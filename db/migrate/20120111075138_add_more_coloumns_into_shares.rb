class AddMoreColoumnsIntoShares < ActiveRecord::Migration
  def up
                 add_column :shares, :user_id, :string
                 add_column :shares, :share_type_id, :integer
                 add_column :shares, :ip_address, :string
  end

  def down
                 remove_column :shares, :user_id, :string
                 remove_column :shares, :share_type_id, :integer
                 remove_column :shares, :ip_address, :string
  end
end
