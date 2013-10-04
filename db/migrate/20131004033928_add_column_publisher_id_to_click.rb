class AddColumnPublisherIdToClick < ActiveRecord::Migration
  def change
    add_column :clicks,:publisher_id,:integer
  end
end
