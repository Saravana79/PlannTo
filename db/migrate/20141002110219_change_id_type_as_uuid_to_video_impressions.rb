class ChangeIdTypeAsUuidToVideoImpressions < ActiveRecord::Migration
  def self.up
    change_column :video_impressions, :id, :uuid
  end

  def self.down
    change_column :video_impressions, :id, :integer
  end
end
