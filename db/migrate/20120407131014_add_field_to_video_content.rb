class AddFieldToVideoContent < ActiveRecord::Migration
  def change
    drop_table :video_contents
    drop_citier_view(VideoContent)
    create_table :video_contents do |t|
      t.string :youtube
    end
    create_citier_view(VideoContent)
  end
end
