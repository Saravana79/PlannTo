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


  def content_vote_count
    count = $redis.get("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.id}")
    if count.nil?
      vote = VoteCount.search_vote(self).first
      count = vote.nil? ? 0 : (vote.vote_count_positive - vote.vote_count_negative)
      $redis.set("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.id}", count)
      return count
    else
      return count
    end
  end


  def self.filter(options)
    if !options.blank?
      options.inject(self) do |scope, (key, value)|
        return scope if value.blank?
        value= value.join(",") if is_a?(Array)
        case key.to_sym
        when :items
          all_items = Item.get_all_related_items_ids(value)
          scope.scoped(:conditions => ['content_item_relations.item_id in (?)', all_items ], :joins => :content_item_relations).uniq
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
        rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
        rel.save!
      end
    end
  end
	
	acts_as_rateable
  acts_as_voteable
  acts_as_commentable

end
