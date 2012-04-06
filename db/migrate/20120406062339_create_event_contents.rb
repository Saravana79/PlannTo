class CreateEventContents < ActiveRecord::Migration
  def change
    create_table :event_contents do |t|
      t.string :url
      t.date :start_date
      t.date :end_date
    end
     create_citier_view(EventContent)
  end
end
