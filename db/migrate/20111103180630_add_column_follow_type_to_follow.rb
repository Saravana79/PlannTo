class AddColumnFollowTypeToFollow < ActiveRecord::Migration
  def self.up
    add_column(:follows, :follow_type, :string)
  end

  def self.down
    remove_column(:follows, :follow_type)    
  end
end
