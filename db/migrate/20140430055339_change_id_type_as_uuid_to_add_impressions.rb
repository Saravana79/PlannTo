class ChangeIdTypeAsUuidToAddImpressions < ActiveRecord::Migration
  def self.up
    change_column :add_impressions, :id, :uuid
  end

  def self.down
    change_column :add_impressions, :id, :integer
    execute("ALTER TABLE `add_impressions` CHANGE `id` `id` INT  NOT NULL AUTO_INCREMENT;")
  end
end