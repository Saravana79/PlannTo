require 'will_paginate/array'

class Content < ActiveRecord::Base
  #used for content description split.
  WORDCOUNT = 50
  DELETE_STATUS = 5
	
  acts_as_citier
  has_many :reports, :as => :reportable, :dependent => :destroy 
  # extend FriendlyId
  # friendly_id :title, use: :slugged

  validates_presence_of :title, :unless => lambda{ |content| content.type == "AnswerContent" } 
  validates_presence_of :description, :if => lambda{ |content| content.type == "AnswerContent" } 
  #below line not required.
  #validates_presence_of :created_bye

  belongs_to :user, :foreign_key => 'updated_by'
  belongs_to :user, :foreign_key => 'created_by'
  has_many :votes
  has_many :content_item_relations
  has_many :item_contents_relations_cache
  has_many :items, :through => :content_item_relations
  belongs_to :itemtype
  has_and_belongs_to_many :guides
  has_one :content_photo
  accepts_nested_attributes_for :content_photo, :allow_destroy => true
  scope :item_contents, lambda { |item_id| joins(:content_item_relations).where('content_item_relations.item_id = ?', item_id)}
  has_many :flags
  has_many :content_itemtype_relations
  has_many :itemtypes, :through => :content_itemtype_relations

  searchable :auto_index => true, :auto_remove => true  do
    text :title, :boost => 3.0, :more_like_this =>true
    text :title , :as => :name_ac
    text :description
    string :sub_type
    integer :total_votes
    integer :status
    integer :comments_count
    time :created_at
    integer :itemtype_ids,  :multiple => true do
      content_itemtype_relations.map {|items| items.itemtype_id}    
    #content.itemtype_id
    end
    integer :item_ids,  :multiple => true do
      item_contents_relations_cache.map {|items| items.item_id}
    end
  end

  def related_items
    return ContentItemRelation.where('content_id = ?', self.id)
  end

  def content_type
    return self.sub_type
  end

  PER_PAGE = 10

  def content_vote_count
    #result = $redis.get("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.id}")
    #if result.nil?
      #vote = VoteCount.search_vote(self).first
      #count = vote.nil? ? 0 : (vote.vote_count_positive - vote.vote_count_negative)
      #comment_count = self.comments.nil? ?  0 : self.comments.count
    #  $redis.set("#{VoteCount::REDIS_CONTENT_VOTE_KEY_PREFIX}#{self.id}", "#{self.total_votes}_#{self.comments_count}")
    return 0 if self.total_votes.nil?
    return self.total_votes
    #else
     # return result.split("_")[0]
    #end
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

        #all_items = Item.get_related_content_for_items(value)
         idstr= value.is_a?(Array) ? value.join(',') : value
        scope.joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in (?)", value ) 
      when :itemtype_id
        str= value.is_a?(String) ? value.split(",") : value
        scope.joins(:content_itemtype_relations).where("content_itemtype_relations.itemtype_id in (?)", str )
      when :guide
        scope.joins(:guides).where("contents_guides.guide_id = ?", value )      
      when :type
        scope.scoped(:conditions => ["#{self.table_name}.type in (?)", value ])
      when :sub_type
        scope.scoped(:conditions => ["#{self.table_name}.sub_type in (?)", value.uniq ])
      when :item_relations 
        scope.joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in (?)", value )
      when :order
        attribute, order = value.split(" ")
        scope.scoped(:order => "#{self.table_name}.#{attribute} #{order}")
      when :user
        scope.scoped(:conditions => ["#{self.table_name}.created_by = ?", value ])
      when :status      
        scope.scoped(:conditions => ["#{self.table_name}.status = ?", 1])
      when :page
        scope.paginate(:page => options["page"], :per_page => options["limit"])
      else
      scope.select("distinct(contents.id), contents.*")
      end      
    end
    scope.uniq #.paginate(:page => options["page"], :per_page => options["limit"])

  end

  def get_content_status(type)
    status = case type
    when "create" then 1
    when "update" then 1
    else
    1
    end
    return status
  end
  
  def self.follow_items_contents(user,item_types,type)
    if item_types.nil? && type.blank?
      items = Follow.where('follower_id =? and followable_type in (?)',user.id,Item::FOLLOWTYPES).collect(&:followable_id).uniq
      @item_types = Itemtype.where("itemtype in (?)", Item::ITEMTYPES).collect(&:id)
   else
      @item_types = item_types.join(",") if !item_types.blank?
      items = Item.get_follows_item_ids_for_user_and_item_types(user,item_types).uniq
    end 
    @article_categories = ArticleCategory.by_itemtype_id(0).collect(&:name)
    @related_items = []
    @related_items += items
    @items = items.join(",")
      items.each do |it| 
        item = Item.find(it)
        if (item.type == "Manufacturer") || (item.type == "CarGroup")
          @related_items += item.related_cars.collect(&:id)
          @related_items.delete(it)
        end
       end
      return @related_items.uniq.join(","),@item_types,@article_categories,@items 
   end
  
  
  def save_with_items!(items)
    # Content.transaction do
    item_type_ids = Array.new
    self.status = get_content_status("create")
    self.save!
    items.split(",").each_with_index do |id, index|
      item = Item.find_by_id(id)
      # rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
      item_type_ids << get_itemtype(item)
      self.update_attribute(:itemtype_id, get_itemtype(item)) if index == 0
      rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
      rel.save!
    end
    item_type_ids.uniq.each do |id|
      ContentItemtypeRelation.create(:itemtype_id => id, :content_id => self.id)
    end
    logger.info "-----------------------------------------"

    #Resque.enqueue(ContentRelationsCache, self.id, items.split(","))
    self.update_item_contents_relations_cache(self)

  #end
  end

  def update_item_contents_relations_cache(content)
    item_ids = Array.new
    itemtype_id = Array.new
    car_group_item_ids = Array.new
    manufacturer_and_cargroup_item_ids = Array.new
    attribute_item_ids = Array.new
    attribute_item_ids = Array.new
    items = content.items
    items.each do |item|
    #item = Item.find(item)
      if item.type == "AttributeTag"
      attribute_item_ids << item.id
      elsif item.type == "Manufacturer"
      #manufacturer_item_ids = item.itemrelationships.collect(&:relateditem_id)
      manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "CarGroup"
      #logger.info item.itemrelationships.collect(&:relateditem_id)
      #car_group_item_ids = item.itemrelationships.collect(&:relateditem_id)
      manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "ItemtypeTag"
      #  itemtype_id << Itemtype.where("itemtype = ? ", item.name.singularize).first.try(:id)
      else
      item_ids << item.id
      end
    end
    if (manufacturer_and_cargroup_item_ids.size != 0 || attribute_item_ids.size != 0 || item_ids.size !=0)

      sql=    "select * from items where "

      # sql += " itemtype_id in (#{itemtype_id.join(",")})" unless itemtype_id.size == 0 #/* needs to be added only when itemtypetag is associated to the content */

      #if itemtype_id.size != 0
      #   sql += " and (" unless   (item_ids.size ==0 && manufacturer_and_cargroup_item_ids.size == 0 && attribute_item_ids.size == 0)
      # end

      sql += "  id in (#{item_ids.join(",")})" unless item_ids.size == 0  #/*needs to add only when products are directly associated to content*/

      if (manufacturer_and_cargroup_item_ids.size != 0 || attribute_item_ids.size != 0)
        sql += " or " unless item_ids.size == 0
        sql += " id in ( "
        sql += "  select item_id from itemrelationships where " unless manufacturer_and_cargroup_item_ids.size == 0  #/* needs to be added only when manufacturer or car group is associated to it */
        sql += " relateditem_id in (#{manufacturer_and_cargroup_item_ids.join(",")}) "  unless manufacturer_and_cargroup_item_ids.size == 0  #/* needs to be added only when manufacturer or car group is associated to it */
        sql += " and item_id in " unless (manufacturer_and_cargroup_item_ids.size == 0 || attribute_item_ids.size == 0)
        sql += "  (select av.item_id from attribute_values av inner join item_attribute_tag_relations iatr on av.attribute_id =iatr.attribute_id and  iatr.value = av.value where iatr.item_id in (#{attribute_item_ids.join(",")}))"  unless attribute_item_ids.size == 0#/*this needs to be added if attribute tag is associated to it */
        sql += ")"
      end
      #if itemtype_id.size != 0
      #  sql += " )" unless   (item_ids.size ==0 && manufacturer_and_cargroup_item_ids.size == 0 && attribute_item_ids.size == 0)
      #end
      relateditems=Item.find_by_sql(sql)
      self.save_content_relations_cache(relateditems.collect(&:id))
    end
  end

  def save_content_relations_cache(related_items)
    new_records = Array.new
    related_items.each do |item|
      new_records << {:item_id => item, :content_id => self.id}
    end
    ItemContentsRelationsCache.create(new_records)
  end

  def get_itemtype(item)
    item.get_base_itemtypeid()
  end

  def update_with_items!(params, items)
    item_type_ids = Array.new
    Content.transaction do
      self.status = get_content_status("update")
      self.update_attributes(params)
      content_item_relations = ContentItemRelation.where("content_id = ?", self.id)
      content_item_relations.destroy_all
      items.split(",").each_with_index do |id, index|
        item = Item.find(id)
        self.update_attribute(:itemtype_id, get_itemtype(item)) if index == 0
        rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
        item_type_ids << get_itemtype(item)
        rel.save!
      end

      ContentItemtypeRelation.delete_all(["content_id = ?", self.id])
      item_type_ids.uniq.each do |id|
        ContentItemtypeRelation.create(:itemtype_id => id, :content_id => self.id)
      end
    end
    #Resque.enqueue(ContentRelationsCache, self.id, items.split(","), true)
    self.remove_old_contents_relations_cache
    self.update_item_contents_relations_cache(self)
  end

  def remove_old_contents_relations_cache
    ItemContentsRelationsCache.delete_all(["content_id = ?", self.id])
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
