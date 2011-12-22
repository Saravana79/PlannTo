class Debate < ActiveRecord::Base
  belongs_to :review
  belongs_to :argument, :polymorphic => true
  belongs_to :user, :foreign_key => 'created_by'
end
