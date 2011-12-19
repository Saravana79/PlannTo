class CreateVoteCounts < ActiveRecord::Migration
  def change
    create_table :vote_counts do |t|
      t.references :voteable, :polymorphic => true, :null => false
      t.integer    :vote_count, :null => false
      t.timestamps
    end
  end
end
