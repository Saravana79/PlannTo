class Content < ActiveRecord::Base
  acts_as_citier

  validates_presence_of :title 
  validates_presence_of :created_by  
  
	belongs_to :user, :foreign_key => 'updated_by'
	belongs_to :user, :foreign_key => 'created_by'
	has_many :content_item_relations
  has_many :items, :through => :content_item_relations
  belongs_to :itemtype
 scope :item_contents, lambda { |item_id| joins(:content_item_relations).where('content_item_relations.item_id = ?', item_id)}


 def self.filter(options)
   if !options.blank?
   options.inject(self) do |scope, (key, value)|
     return scope if value.blank?
     value= value.join(",") if is_a?(Array)
     case key.to_sym
     when :items
       scope.scoped(:conditions => ['content_item_relations.item_id in (?)', value ], :joins => :content_item_relations)
     when :type
       scope.scoped(:conditions => ["#{self.table_name}.type in (?)", value ])
     when :order
       attribute, order = value.split(" ") 
       scope.scoped(:order => "#{self.table_name}.#{attribute} #{order}")
     when :limit
       scope.limit(value)
     else 
       scope
     end
   end 
 else
   Content.limit(10)
 end
  end
  
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
