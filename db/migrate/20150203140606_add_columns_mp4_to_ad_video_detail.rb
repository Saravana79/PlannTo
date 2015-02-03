class AddColumnsMp4ToAdVideoDetail < ActiveRecord::Migration
  def change
    add_column :ad_video_details, :mp4, :string
  end
end
