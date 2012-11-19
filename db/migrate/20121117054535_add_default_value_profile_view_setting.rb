class AddDefaultValueProfileViewSetting < ActiveRecord::Migration
  def up
    change_column :users, :profile_view_setting, :string, :default => "pu"
    User.all.each do |u|
      u.update_attribute("profile_view_setting","pu")
    end
  end

  def down
  end
end
