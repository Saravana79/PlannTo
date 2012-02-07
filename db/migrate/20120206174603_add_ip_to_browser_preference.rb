class AddIpToBrowserPreference < ActiveRecord::Migration
  def change
    add_column :browser_preferences, :ip, :string
  end
end
