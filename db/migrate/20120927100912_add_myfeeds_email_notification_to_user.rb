class AddMyfeedsEmailNotificationToUser < ActiveRecord::Migration
  def change
    add_column :users,:my_feeds_email,:boolean,:default => true
  end
end
