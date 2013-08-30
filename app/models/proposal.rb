class Proposal < ActiveRecord::Base
  belongs_to :item
  belongs_to :vendor,:class_name => "Item", :foreign_key => "vendor_id"
  belongs_to :buying_plan
  acts_as_commentable
  
  def self.select_items_option_list(buying_plan_id)
    Proposal.where(:buying_plan_id => buying_plan_id).group("item_id").map{|p|[p.item.name,p.item_id]} rescue []
  end  
end
