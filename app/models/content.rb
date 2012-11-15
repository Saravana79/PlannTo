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
    text :title , :as => :name_ac
    text :title, :boost => 3.0, :more_like_this =>true
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

  def sort_by
    created_at
  end
  
  def self.filter(options)
    options ||= {:page => 1, :limit => 10}
    options["page"]||=1
    options["limit"]||=PER_PAGE
    options["order"]||="created_at desc"

    if options["search_type"] == "activities"
        type_1 = options["sub_type"].length > 1 ? options["sub_type"] + ["User","Answer"]  : options["sub_type"]
       type = type_1[0] == "Q&A" ? type_1 + ["Answer"] : type_1
       UserActivity.where("user_id =? and related_activity_type in (?)",options["user"],type).where("related_id is not null").order("time desc").paginate(:page => options["page"], :per_page => options["limit"])
     else  
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
         if value == ['Video']
           scope.joins("INNER JOIN `article_contents` ON article_contents.id = contents.id").where("article_contents.video =?",1)
         else           
           scope.scoped(:conditions => ["#{self.table_name}.sub_type in (?)", value])  
         end   
      when :item_relations 
        scope.joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in (?)", value )
      when :order
        attribute, order = value.split(" ")
        scope.scoped(:order => "#{self.table_name}.#{attribute} #{order}")
      when :my_feed
         scope.scoped(:conditions => ["#{self.table_name}.created_at >= ? OR #{self.table_name}.created_by in(?)", 2.weeks.ago,value])
      when :user
        scope.scoped(:conditions => ["#{self.table_name}.created_by =?", value ])
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
  end
  
  def self.my_feeds_filter(filter_params)
     item_type_ids = filter_params["itemtype_id"].is_a?(String) ? filter_params["itemtype_id"].split(",") : filter_params["itemtype_id"]
     content_ids = filter_params["content_ids"].is_a?(String) ? filter_params["content_ids"].split(",") : filter_params["content_ids"]
     sub_type = filter_params["sub_type"].is_a?(String) ? filter_params["sub_type"].split(",") : filter_params["sub_type"]
      type_1 = sub_type.length > 1 ? sub_type + ["Answer","User"]  : sub_type
      sub_type = type_1[0] == "Q&A" ? type_1 + ["Answer"] : type_1
      sub_type = sub_type.map { |i| "'" + i.to_s + "'" }.join(",")
      item_ids = filter_params["items_id"].is_a?(String) ? filter_params["items_id"].split(',') : filter_params["items_id"]
     root_item_ids = filter_params["root_items"].is_a?(String) ? filter_params["root_items"].split(',') : filter_params["root_items"]
     vote_count = configatron.root_content_vote_count
     page = (filter_params["page"].to_i - 1) * 10

  if  filter_params["sub_type"] == ["Video"]
       content_ids=  Content.find_by_sql("select * from (SELECT distinct(contents.id) as content_id,contents.created_at as created_time ,null as activity_id FROM contents 
INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
INNER JOIN content_itemtype_relations ON content_itemtype_relations.content_id = contents.id INNER JOIN article_contents on  article_contents.id = contents.id
WHERE 
(
(item_contents_relations_cache.item_id in (#{item_ids.blank? ? 0 : item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 : root_item_ids.join(",")}) and total_votes >= #{vote_count}) 
)and 
(content_itemtype_relations.itemtype_id in (#{item_type_ids.join(",")}) and (article_contents.video=1)  and contents.status =1)
union 
 (select related_id as content_id, time as created_time, id as activity_id from user_activities where  user_id in (#{filter_params["created_by"].blank? ? 0 : filter_params["created_by"].join(",")}) and related_activity_type in (#{sub_type}) and related_id is not null)
 )a  order by a.created_time desc limit #{PER_PAGE} OFFSET #{page}").collect(&:id)
else 
  contents =  Content.find_by_sql("select * from (SELECT distinct(contents.id) as content_id, contents.created_at as created_time ,null as activity_id FROM contents 
INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
INNER JOIN content_itemtype_relations ON content_itemtype_relations.content_id = contents.id 
WHERE 
(
(item_contents_relations_cache.item_id in (#{item_ids.blank? ? 0 : item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 : root_item_ids.join(",")}) and total_votes >= #{vote_count}) 
)and 
(content_itemtype_relations.itemtype_id in (#{item_type_ids.join(",")}) and contents.sub_type in (#{sub_type}) and contents.status =1)
union 
 (select related_id as content_id, time as created_time, id as activity_id from user_activities where (user_id in (#{filter_params["created_by"].blank? ? 0 : filter_params["created_by"].join(",")}) or related_id in (#{filter_params["content_ids"].blank? ? 0 : filter_params["content_ids"].join(",")})) and related_activity_type in (#{sub_type}) and related_id is not null)
)a  order by a.created_time desc limit #{PER_PAGE} OFFSET #{page}")

end
   content_ids  = []
   activity_ids = []
   contents.map{ |c| content_ids << c.content_id if c.activity_id == nil} rescue ''
   contents.map{ |c| activity_ids << c.activity_id  if c.activity_id != nil} rescue ''
   content_ids = content_ids.blank? ? "" : content_ids
   activity_ids = activity_ids.blank? ? "" : activity_ids
   contents_1 = Content.find(:all, :conditions => ['id in (?)',content_ids] ,:order => filter_params["order"])
   activity_contents = UserActivity.where("id in (?)", activity_ids).group(:id).order("time desc")
   contents = ((contents_1 + activity_contents).sort{|x,y| x.sort_by <=> y.sort_by}).reverse
  # contents = Content.find(content_ids)
 end
 
  def self.follow_content_ids(current_user,categories)
    current_user.follows.where('followable_type in (?)',categories).collect(&:followable_id)
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
      @item_types = Itemtype.where("itemtype in (?)", Item::ITEMTYPES).collect(&:id)
       @items,@root_items = Item.find_top_level_item_ids(Item::FOLLOWTYPES,user)
   else
      @item_types = item_types.join(",") if !item_types.blank?
      @items,@root_items = Item.get_follows_item_ids_for_user_and_item_types(user,item_types).uniq
    end 
    @article_categories = ArticleCategory.by_itemtype_id(0).collect(&:name)
     return @items.uniq.join(","),@item_types,@article_categories,@root_items
   end
  
  def  remove_user_activities
    UserActivity.where('related_activity_type !=? and related_id =?', "User",self.id).each do |a|
      a.destroy
    end
    if self.sub_type == "Q&A"
      answer_ids = self.answer_contents.collect(&:id)
      UserActivity.where("related_activity_type !=? and related_id in (?)",'User',answer_ids).each do |an|
      an.destroy
    end 
    end  
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
      itemtype_id << item.get_base_itemtypeid
      elsif item.type == "Manufacturer"
      #manufacturer_item_ids = item.itemrelationships.collect(&:relateditem_id)
      manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "CarGroup"
      #logger.info item.itemrelationships.collect(&:relateditem_id)
      #car_group_item_ids = item.itemrelationships.collect(&:relateditem_id)
      manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "ItemtypeTag"
        itemtype_id << Itemtype.where("itemtype = ? ", item.name.singularize).first.try(:id)
      else
      item_ids << item.id
      end
    end
    if (manufacturer_and_cargroup_item_ids.size != 0 || attribute_item_ids.size != 0 || item_ids.size !=0)

      sql=    "select * from items where "

      

      #if itemtype_id.size != 0
      #   sql += " and (" unless   (item_ids.size ==0 && manufacturer_and_cargroup_item_ids.size == 0 && attribute_item_ids.size == 0)
      # end

      sql += " ( id in (#{item_ids.join(",")})" unless item_ids.size == 0  #/*needs to add only when products are directly associated to content*/

      if (manufacturer_and_cargroup_item_ids.size != 0 || attribute_item_ids.size != 0)
        sql += " or " unless item_ids.size == 0
        sql += " id in ( "
        sql += "  select item_id from itemrelationships where " unless manufacturer_and_cargroup_item_ids.size == 0  #/* needs to be added only when manufacturer or car group is associated to it */
        sql += " relateditem_id in (#{manufacturer_and_cargroup_item_ids.join(",")}) "  unless manufacturer_and_cargroup_item_ids.size == 0  #/* needs to be added only when manufacturer or car group is associated to it */
        sql += " and item_id in " unless (manufacturer_and_cargroup_item_ids.size == 0 || attribute_item_ids.size == 0)
        sql += "  (select av.item_id from attribute_values av inner join item_attribute_tag_relations iatr on av.attribute_id =iatr.attribute_id and  iatr.value = av.value where iatr.item_id in (#{attribute_item_ids.join(",")}))"  unless attribute_item_ids.size == 0#/*this needs to be added if attribute tag is associated to it */
        sql += ")"
        sql += " )" unless item_ids.size == 0
         sql += " and itemtype_id in (#{itemtype_id.join(",")})" unless itemtype_id.size == 0 #/* needs to be added only when itemtypetag is associated to the content */
      else 
        sql += " )" unless item_ids.size == 0
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

  def can_update_content?(current_user)
   return false if !current_user
   if current_user.is_admin? || current_user.id == self.created_by 
     return true
   end
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
