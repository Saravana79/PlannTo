class ModifyContentForMti < ActiveRecord::Migration
  def up
    add_column :contents, :ip_address, :string
  end

  def down
    remove_column :contents, :ip_address
  end
end
