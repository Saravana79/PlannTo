class Review < ActiveRecord::Base
  belongs_to :item
  belongs_to :user, :foreign_key => 'created_by'
  has_many :debates
  has_many :pros, :through => :debates, :source => :argument, :source_type => 'Pro'
  has_many :cons, :through => :debates, :source => :argument, :source_type => 'Con'
  has_many :best_uses, :through => :debates, :source => :argument, :source_type => 'Best_Use'

  accepts_nested_attributes_for :pros,:cons,:best_uses

  acts_as_rateable
  acts_as_voteable
end
