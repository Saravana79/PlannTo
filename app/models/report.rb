class Report < ActiveRecord::Base
   ReportTypes = [["Duplicate Content","Duplicate Content"],["Copyright Issue","Copyright Issue"],["Spam","Spam"],["Others","Others"]] 
   validates_presence_of :report_type
   validates_presence_of :description
   belongs_to :reportable, :polymorphic => true
   belongs_to :user, :foreign_key => 'reported_by'
end
