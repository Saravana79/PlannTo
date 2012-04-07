class CreateEventContents < ActiveRecord::Migration
   def up
    create_table :event_contents do |t|
      t.string :url
      t.date :start_date
      t.date :end_date
      t.string :location
    end
     create_citier_view(EventContent)
  end

   def down
  	drop_table :event_contents
  	drop_citier_view(EventContent)
  end
end
