class ChangeColumnSidToSidAdDetails < ActiveRecord::Migration
  def up
    change_column :sid_ad_details, :sid, :string
  end

  def down
    change_column :sid_ad_details, :sid, :integer
  end
end
