class VoteCount < ActiveRecord::Base
  require 'global_utilities'

  # scope :order_by_votes, lambda { |*args| where(["voteable_type = ?", args.first.class.name]).order(:vote_count) }
  scope :search_vote, lambda {|voteable| where("voteable_id = ? and voteable_type = ?", voteable.id, GlobalUtilities.get_class_name(voteable.class.name)) }


  belongs_to :voter, :polymorphic => true
  belongs_to :voteable, :polymorphic => true
end
