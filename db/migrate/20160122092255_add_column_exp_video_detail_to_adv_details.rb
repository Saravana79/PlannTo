class AddColumnExpVideoDetailToAdvDetails < ActiveRecord::Migration
  def change
    add_column :adv_details, :exp_video_width, :string
    add_column :adv_details, :exp_video_height, :string
  end
end
