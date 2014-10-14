class AddSiteStatusColumnToSourceCategory < ActiveRecord::Migration
  def change
    add_column :source_categories, :site_status, :boolean, :default => true
  end
end
