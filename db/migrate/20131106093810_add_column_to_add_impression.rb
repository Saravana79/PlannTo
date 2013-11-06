class AddColumnToAddImpression < ActiveRecord::Migration
  def change
    add_column :add_impressions,:itemsaccess,:string
    add_column :add_impressions,:params,:string
  end
end
