class AddIndexPublisherUrlForPublishers < ActiveRecord::Migration
  def change
    add_index :publishers, :publisher_url
  end
end
