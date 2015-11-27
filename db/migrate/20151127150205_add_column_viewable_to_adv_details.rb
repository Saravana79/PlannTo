class AddColumnViewableToAdvDetails < ActiveRecord::Migration
  def change
    add_column :adv_details, :viewable, :boolean, :default => true
  end
end
