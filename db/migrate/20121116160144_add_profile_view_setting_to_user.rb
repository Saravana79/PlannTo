class AddProfileViewSettingToUser < ActiveRecord::Migration
  def change
    add_column :users,:profile_view_setting,:string
  end
end
