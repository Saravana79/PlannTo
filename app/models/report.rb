class Report < ActiveRecord::Base
   belongs_to :reportable, :polymorphic => true
   belongs_to :reported_by, :class_name => "User"
end
