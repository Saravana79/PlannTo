class AddColumnFromPlanntoToConversionPixelDetails < ActiveRecord::Migration
  def change
    add_column :conversion_pixel_details, :from_plannto, :boolean, :default => false
  end
end
