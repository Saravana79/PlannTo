class CreateAdVideoDetails < ActiveRecord::Migration
  def change
    create_table :ad_video_details do |t|
      t.integer :advertisement_id
      t.string :flv
      t.string :wmv
      t.string :webm
      t.string :total_time
      t.boolean :skip
      t.string :skip_time
      t.string :linear_click_url
      t.string :non_linear_img_url
      t.string :non_linear_click_url
      t.string :companion_type
      t.string :companion_img_url
      t.string :companion_click_url
      t.timestamps
    end
  end
end
