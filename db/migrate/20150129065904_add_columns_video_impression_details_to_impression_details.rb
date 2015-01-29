class AddColumnsVideoImpressionDetailsToImpressionDetails < ActiveRecord::Migration
  def change
    add_column :impression_details, :video, :boolean, :default => false
    add_column :impression_details, :video_impression_id, :uuid
  end
end
