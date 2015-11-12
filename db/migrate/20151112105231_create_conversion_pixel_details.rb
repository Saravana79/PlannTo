class CreateConversionPixelDetails < ActiveRecord::Migration
  def change
    create_table :conversion_pixel_details do |t|
      t.string :plannto_user_id
      t.string :ref_url
      t.datetime :conversion_time
      t.string :source
      t.string :params
      t.timestamps
    end
  end
end
