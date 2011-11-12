class Compare < ActiveRecord::Base

  belongs_to :comparable, :polymorphic => true

end
