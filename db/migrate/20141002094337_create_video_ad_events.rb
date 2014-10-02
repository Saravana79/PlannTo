class CreateVideoAdEvents < ActiveRecord::Migration
  def change
    create_table :video_ad_events do |t|
      t.uuid :video_impression_id
      t.string :event_name
      t.timestamps
    end
  end
end
