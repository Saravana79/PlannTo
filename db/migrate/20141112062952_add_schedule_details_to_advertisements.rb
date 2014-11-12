class AddScheduleDetailsToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :schedule_details, :string
  end
end
