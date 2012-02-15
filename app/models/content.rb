class Content < ActiveRecord::Base
  acts_as_citier
  validates_presence_of :title  
	belongs_to :user, :foreign_key => 'updated_by'
	belongs_to :user, :foreign_key => 'created_by'
	has_many :content_item_relations

  
	def save_with_items!(items)
	  Content.transaction do
	    self.save!
      items.split(",").each do |id|
        item = Item.find(id)
        rel= ContentItemRelation.new(:item => item, :content => self)
        rel.save!
      end
    end
  end
	
	acts_as_rateable
  acts_as_voteable
  acts_as_commentable

end
