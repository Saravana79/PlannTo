class Proposal < ActiveRecord::Base
  belongs_to :item
  belongs_to :vendor
end
