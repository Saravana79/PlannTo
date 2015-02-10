class AddColumnVideoDetailsToAdVideoDetails < ActiveRecord::Migration
  def change
    add_column :ad_video_details, :video_details, :string
  end
end
