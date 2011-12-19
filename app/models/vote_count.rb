class VoteCount < ActiveRecord::Base

  # scope :order_by_votes, lambda { |*args| where(["voteable_type = ?", args.first.class.name]).order(:vote_count) }

  belongs_to :voter, :polymorphic => true
  belongs_to :voteable, :polymorphic => true
end
