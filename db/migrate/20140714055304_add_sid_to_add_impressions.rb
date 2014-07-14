class AddSidToAddImpressions < ActiveRecord::Migration
  def change
    add_column :add_impressions, :sid, :string
  end
end
