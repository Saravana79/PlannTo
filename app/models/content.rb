require 'will_paginate/array'
class Content < ActiveRecord::Base
  #used for content description split.
  WORDCOUNT = 50
  
  acts_as_citier

  validates_presence_of :title 
  validates_presence_of :created_by  
  
	belongs_to :user, :foreign_key => 'updated_by'
	belongs_to :user, :foreign_key => 'created_by'
	has_many :content_item_relations
  has_many :items, :through => :content_item_relations
  belongs_to :itemtype
  scope :item_contents, lambda { |item_id| joins(:content_item_relations).where('content_item_relations.item_id = ?', item_id)}

  searchable :auto_index => true, :auto_remove => true  do
    text :title, :boost => 3.0, :more_like_this =>true
    text :description
    string :sub_type
  end
  
  def related_items
    return ContentItemRelation.where('content_id = ?', self.id)  
  end

  def content_type
    return self.sub_type
  end

  PER_PAGE = 10
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
    options ||= {:page => 1, :limit => 10} 
    options["page"]||=1 
    options["limit"]||=PER_PAGE 
    options["order"]||="created_at desc" 
    scope=options.inject(self) do |scope, (key, value)|

      return scope if value.blank?
      value= value.join(",") if is_a?(Array)
      case key.to_sym
      when :items
        # all_items = Item.get_all_related_items_ids(value)
        #  scope.scoped(:conditions => ['content_item_relations.item_id in (?)', all_items ], :joins => :content_item_relations)
     
        all_items = Item.get_related_content_for_items(value)
        scope.scoped(:conditions => ['id in (?)',all_items])
      when :itemtype_id
        scope.scoped(:conditions => ["#{self.table_name}.itemtype_id = ?", value ])
      when :type
        scope.scoped(:conditions => ["#{self.table_name}.type in (?)", value ])
      when :sub_type
        scope.scoped(:conditions => ["#{self.table_name}.sub_type in (?)", value ])
      when :order
        attribute, order = value.split(" ")
        scope.scoped(:order => "#{self.table_name}.#{attribute} #{order}")
      else
        scope
      end
    end
    scope.uniq.paginate(:page => options["page"], :per_page => options["limit"])
  
  end
  
	def save_with_items!(items)
	  Content.transaction do
	    self.save!
      items.split(",").each_with_index do |id, index|
        item = Item.find(id)
        # rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
        self.update_attribute(:itemtype_id, get_itemtype(item)) if index == 0
        rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
        rel.save!
      end
    end
  end

  def get_itemtype(item)
    itemtype_id = case item.type
    when "AttributeTag" then ItemAttributeTagRelation.where("item_id = ? ", item.id).first.try(:itemtype_id)
    when "Manufacturer" then item.itemrelationships.first.related_cars.itemtype_id
    when "CarGroup" then item.itemrelationships.first.items.itemtype_id
    when "ItemtypeTag" then Itemtype.where("itemtype = ? ", item.name.singularize).first.try(:id)
    else item.itemtype_id
    end
    return itemtype_id
  end

  def update_with_items!(params, items)
    Content.transaction do
	    self.update_attributes(params)
      content_item_relations = ContentItemRelation.where("content_id = ?", self.id)
      content_item_relations.destroy_all
      items.split(",").each_with_index do |id, index|
        item = Item.find(id)
        self.update_attribute(:itemtype_id, get_itemtype(item)) if index == 0
        rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
        rel.save!
      end
    end
  end

  def can_update_content?(user)
    return false if !user
    return false if user.id != self.created_by
    return true
  end

	def is_review_content?
    self.type == "ReviewContent"
  end

  def is_article_content?
    self.type == "ArticleContent"
  end

  def is_event?
    self.sub_type == ArticleCategory::EVENT
  end

  def is_review?
    self.sub_type == ArticleCategory::REVIEWS
  end

  def is_app?
    self.sub_type == ArticleCategory::APPS
  end

  def is_books?
    self.sub_type == ArticleCategory::BOOKS
  end

  def is_accessories?
    self.sub_type == ArticleCategory::ACCESSORIES
  end

  def is_question_content?
    self.type == "QuestionContent"
  end  

	acts_as_rateable
  acts_as_voteable
  acts_as_commentable

end
