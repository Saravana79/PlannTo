class Report < ActiveRecord::Base
   validates_presence_of :report_type
   validates_presence_of :description
   belongs_to :reportable, :polymorphic => true
   belongs_to :user, :foreign_key => 'reported_by'
end
