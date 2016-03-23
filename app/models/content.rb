require 'will_paginate/array'
require 'net/http'
require 'rexml/document'
class Content < ActiveRecord::Base
  #used for content description split.
  WORDCOUNT = 50
  DELETE_STATUS = 5
  SENT_APPROVAL =6
  REJECTED = 7
  acts_as_citier
  has_many :reports, :as => :reportable, :dependent => :destroy 
  # extend FriendlyId
  # friendly_id :title, use: :slugged
  has_many :impressions, :as=>:impressionable
  has_one :facebook_count
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
  has_many :allitems,:class_name => 'Item', :through => :item_contents_relations_cache, :source => :item
  belongs_to :itemtype
  has_and_belongs_to_many :guides
  has_one :content_photo
  accepts_nested_attributes_for :content_photo, :allow_destroy => true
  scope :item_contents, lambda { |item_id| joins(:content_item_relations).where('content_item_relations.item_id = ?', item_id)}
  has_many :flags
  has_many :content_itemtype_relations
  has_many :itemtypes, :through => :content_itemtype_relations
  has_many :item_pro_cons, :foreign_key => 'article_content_id'
  # after_save :remove_ad_item_ids_from_redis

  # searchable :auto_index => true, :auto_remove => true  do
  #   text :title, :boost => 3.0, :more_like_this =>true do |item|
  #      item.title.gsub("_","") rescue ''
  #    end
  #   text :description do |item|
  #     item.description
  #   end
  #   string :sub_type
  #   integer :total_votes   do |content|
  #       content.total_votes  
  #   end
  #   integer :comments_count
  #   time :created_at
  #   text :name, :boost => 6.0,  :as => :name_ac do |content|
  #     content.title.gsub("_","") rescue ''
  #   end
  #   string :status   do |content|
  #     content.status.to_s
  #   end
  #   integer :orderbyid  do |content|
  #     100
  #   end

  #   integer :itemtype_ids,  :multiple => true do
  #     content_itemtype_relations.map {|items| items.itemtype_id}    
  #   #content.itemtype_id
  #   end
  #   integer :item_ids,  :multiple => true do
  #     item_contents_relations_cache.map {|items| items.item_id}
  #   end
  # end
  
  def self.total_number_of_contents(type,sub_type)
    itemtype = Itemtype.where(:itemtype => type).first
    return Content.where(:sub_type => sub_type,:itemtype_id => itemtype.id,:status => 1).count
  end
  
 
  def facebook_count_save
    #not working
    unless self.url.blank? or self.url.nil?
      url = "http://api.facebook.com/restserver.php?method=http://tech2.in.com/how-to/smartphones/how-to-root-the-samsung-galaxy-s4-i9500/873750"
      xml_data = Net::HTTP.get_response(URI.parse(url)).body
      doc = REXML::Document.new(xml_data)
      counts = []
      doc.elements.each('share_count/ / /') do |ele|
        counts << ele.text
      end
      f_c = FacebookCount.find_by_content_id(self.id)
      if f_c.nil? or f_c.blank?
        #create new row in facebookcounts table
      else
        #update column in facebookcounts table
      end 
    end  
  end

  
  def self.latest_contents(type)
    itemtype = Itemtype.where(:itemtype => type).first
    Content.where(:itemtype_id => itemtype.id,:status => 1).order('created_at desc').limit(3)
  end
  
  def self.get_top_active_deals(item_ids)
    ArticleContent.joins(:item_contents_relations_cache).where("item_contents_relations_cache.item_id in (?) and sub_type=? and status=? and field3=? and (field1>=? or field1 = '')",item_ids.split(","),"Deals",1,'0', Time.zone.now.to_date.strftime("%d/%m/%Y")).group('item_contents_relations_cache.content_id').order('item_contents_relations_cache.created_at desc').limit(10)
  end
   
  def impression_count
    impressions.size
  end
  
  def self.title_display(title)
    if title.length > 60
      title = title[0..59] + "...."
    else
       title
    end   
  end
  
  def sent_approval?
    if self.status == Content::SENT_APPROVAL
      return true
    else
      return false  
    end  
  end
  
  def deleted?
    if self.status == Content::DELETE_STATUS
      return true
    else
      return false  
    end  
  end
  
  def rejected?
    if self.status == Content::REJECTED
      return true
    else
      return false  
    end  
  end
  
  def self.save_thumbnail_using_uploaded_image(article)
    description = article.description
    photos_ids = []
    article.update_attribute('thumbnail',"")
    URI.extract(description).each do |u|
      if u.include?("s3.amazonaws.com")
        id = u.split("/")[6]
        photos_ids << id.to_i
        photos_ids = photos_ids.sort.reverse!
    #    photos_ids.each do | id | 
     #     string = "thumb#{id}"
      #    final_string = "<div id=\"#{string}\"></div>"
       #   if article.description.include?(final_string)
        #    @thumbnail = "true"
         #   photo = ContentPhoto.find(id)
          #  photo.update_attribute('content_id',article.id)
          #  thumb = photo.photo.url(:thumb)
           # article.description =  article.description.gsub(final_string.to_s,"")
            # article.update_attribute('thumbnail',thumb)
         # end
          #end
          
        end
     end
     unless photos_ids.blank?
       id = photos_ids.first
       photo = ContentPhoto.find(id)
       photo.update_attribute('content_id',article.id)
       thumb = photo.photo.url(:thumb)
       article.update_attribute('thumbnail',thumb)
     end  
   end
   
  def deal_expired?
    date = self.field1.to_date rescue ''
    completed = self.field3
    unless date == ''
      if date && date < Date.today.to_date
        return true
      end
    end
    
    if completed.to_i == 1
       return true
    end      
     return false 
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
        if(attribute == "total_votes")          
          attribute = ("(ifnull(total_votes,0) + (ifnull((facebook_counts.like_count + facebook_counts.share_count),0)/10))")
          scope.joins(:facebook_count).scoped(:order => "#{attribute} #{order}")
        else
          scope.scoped(:order => "#{self.table_name}.#{attribute} #{order}")
        end
        
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
  
  def self.my_feeds_filter(filter_params,current_user)
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
       contents =  Content.find_by_sql("select * from (SELECT distinct(contents.id) as content_id,contents.created_at as created_time ,null as activity_id FROM contents 
INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
INNER JOIN content_itemtype_relations ON content_itemtype_relations.content_id = contents.id INNER JOIN article_contents on  article_contents.id = contents.id
WHERE 
(
(item_contents_relations_cache.item_id in (#{item_ids.blank? ? 0 : item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 : root_item_ids.join(",")}) and total_votes >= #{vote_count} and contents.created_by != #{current_user.id} and status in (1)) 
)and 
(content_itemtype_relations.itemtype_id in (#{item_type_ids.join(",")}) and (article_contents.video=1)  and contents.status in (1) and contents.created_by != #{current_user.id})
union 
 (select related_id as content_id, time as created_time, id as activity_id from user_activities where (user_id in (#{filter_params["created_by"].blank? ? 0 : filter_params["created_by"].join(",")}) or (related_id in (#{filter_params["content_ids"].blank? ? 0 : filter_params["content_ids"].join(",")}) and related_activity_type!='User' and user_id!= #{current_user.id})) and related_activity_type in (#{sub_type}) and related_id is not null)
)a  order by a.created_time desc limit #{PER_PAGE} OFFSET #{page}")
else 
  contents =  Content.find_by_sql("select * from (SELECT distinct(contents.id) as content_id, contents.created_at as created_time ,null as activity_id FROM contents 
INNER  JOIN item_contents_relations_cache ON item_contents_relations_cache.content_id = contents.id 
INNER JOIN content_itemtype_relations ON content_itemtype_relations.content_id = contents.id 
WHERE 
(
(item_contents_relations_cache.item_id in (#{item_ids.blank? ? 0 : item_ids.join(",")})) or 
(item_contents_relations_cache.item_id in (#{root_item_ids.blank? ? 0 : root_item_ids.join(",")}) and total_votes >= #{vote_count} and contents.created_by != #{current_user.id} and contents.status in (1))
)and 
(content_itemtype_relations.itemtype_id in (#{item_type_ids.join(",")}) and contents.sub_type in (#{sub_type}) and  contents.status in (1)  and contents.created_by != #{current_user.id})
union 
 (select related_id as content_id, time as created_time, id as activity_id from user_activities  where (user_id in (#{filter_params["created_by"].blank? ? 0 : filter_params["created_by"].join(",")}) or (related_id in (#{filter_params["content_ids"].blank? ? 0 : filter_params["content_ids"].join(",")}) and related_activity_type!='User' and user_id!= #{current_user.id})) and related_activity_type in (#{sub_type}) and related_id is not null)
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
    categories = ArticleCategory.by_itemtype_id(0).collect(&:name)
    return @items.uniq.join(","),@item_types,categories,@root_items
   end
  
  def  remove_user_activities
    UserActivity.where('related_activity_type !=? and related_activity_type !=? and related_id =?', "User","Buying Plan",self.id).each do |a|
      a.destroy
    end
    if self.sub_type == "Q&A" && self.is_a?(QuestionContent)
      answer_ids = self.answer_contents.collect(&:id)
      UserActivity.where("related_activity_type !=? and related_activity_type !=? and  related_id in (?)",'User','Buying Plan', answer_ids).each do |an|
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
      #attribute_item_ids << item.id
      itemtype_id << item.get_base_itemtypeid
      elsif item.type == "Manufacturer"
      #manufacturer_item_ids = item.itemrelationships.collect(&:relateditem_id)
      #manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "CarGroup"
      #logger.info item.itemrelationships.collect(&:relateditem_id)
      #car_group_item_ids = item.itemrelationships.collect(&:relateditem_id)
      manufacturer_and_cargroup_item_ids << item.id
      elsif item.type == "Place"
       item_ids << item.related_city.id unless  item.related_city.nil?
      elsif item.type == "ItemtypeTag"
        itemtype_id << Itemtype.where("itemtype = ? ", item.name.singularize).first.try(:id)
      end
      item_ids << item.id

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

      relateditems = Item.find_by_sql(sql)

      self.save_content_relations_cache(relateditems.collect(&:id))

      relateditems.each do |item|
        unless(item.slug.nil?)
          item_type = item.type.blank? ? "" : item.type.downcase.pluralize
          cache_key = "views/" + configatron.hostname.to_s + "/" + item_type + "/" + item.slug + "?user="
          Rails.cache.delete(cache_key + "1")
          Rails.cache.delete(cache_key + "0")
        end
      end 
        cache_key = "views/" + configatron.hostname.to_s + "/contents/" + content.id.to_s
        Rails.cache.delete(cache_key)
        cache_key = "views/" + configatron.hostname.to_s + "/external_contents/" + content.id.to_s
        Rails.cache.delete(cache_key)
    end


    # if (self.is_a?(ArticleContent) || self.is_a?(VideoContent)) && !self.url.blank?
    if (self.type == "ArticleContent" || self.type == "VideoContent") && !self.url.blank?
      # create content hash in redis-2
      #$redis.HMSET("url:#{self.url}", "item_ids", item_ids, "id", self.id, "article_type", self.sub_type, "itemtype", self.itemtype_id, "count", 0)
      # Resque.enqueue(UpdateRedis, "url:#{self.url}", "item_ids", relateditems.collect(&:id).join(","), "id", self.id, "article_type", self.sub_type, "itemtype", self.itemtype_id, "count", 0)
      # we can't target properly if relateditems count greater than 25
      related_item_ids = items.count < 15 ? relateditems.collect(&:id).join(",") : ""
      redis_key = "url:#{self.url}"
      redis_values = "item_ids", related_item_ids, "id", self.id, "article_type", self.sub_type, "itemtype", self.itemtype_id, "count", 0
      $redis_rtb.HMSET(redis_key, redis_values)
      remove_ad_item_ids_from_redis
    end
  end


def populate_pro_con
    content = self
    ItemProCon.delete_all(["article_content_id = ?", content.id])
    #item_pro = content.itemtype.pro_con_categories.where(:proorcon => "Pro")
    #item_con = content.itemtype.pro_con_categories.where(:proorcon => "Con")
    unless(content.field2.nil? or content.field2.empty?)      
      pros = (content.field2.include? ";") ? content.field2.split(/[.]\s|;/) : content.field2.split(/,|[.]\s/) 
    else
      pros = []
    end
    unless(content.field3.nil? or content.field3.empty?)
      cons =  (content.field3.include? ";") ? content.field3.split(/[.]\s|;/) : content.field3.split(/,|[.]\s/) 
    else
      cons = []
    end
    #last_index += 1

    pros.each do |pro|
     unless (pro.length < 3 )      
        if(pro.strip[0..2].downcase == "and")
          pro = pro[4..-1]
        else
          pro = pro
        end
         pro = pro.capitalize
          tempid =  nil
          content.itemtype.pro_con_categories.order(:sort_order).each do |pcc|
               pro_con_category_id = pcc.id
               list = pcc.list.downcase.strip.gsub(", ","|").gsub(",","|")
               if(pro.downcase.match(/#{list}/))
                    tempid = pcc.id
                    break
               end
                                            
          end
           items = content.item_contents_relations_cache
           items.each do |item|
            itemprocon = ItemProCon.new
            itemprocon.item_id = item.item_id
            itemprocon.article_content_id = content.id
            itemprocon.proorcon = "Pro"
            itemprocon.text = pro.strip
            itemprocon.pro_con_category_id = tempid 
            itemprocon.letters_count = pro.length, 
            itemprocon.words_count = pro.scan(/\w+/).size
            itemprocon.save
            #ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.item_id, content.id, "Pro", pro.strip, pro_con_category_id: tempid , text: pro.strip, index: last_index, proandcon: "Pro", letters_count: pro.length, words_count: pro.scan(/\w+/).size) 
           end
      end 
    end
    cons.each do |con|            
      unless (con.length < 3 )      
       
            if(con.strip[0..2].downcase == "and")
              con = con[4..-1]
            else
              con = con
            end
             con = con.capitalize             
              tempid =  nil
              content.itemtype.pro_con_categories.each do |pcc|
                   pro_con_category_id = pcc.id
                   list = pcc.list.downcase.strip.gsub(", ","|").gsub(",","|")
                  if(con.downcase.match(/#{list}/))
                        tempid = pcc.id
                        break
                   end                                  
              end
            items = content.item_contents_relations_cache
            items.each do |item|
                  itemprocon = ItemProCon.new
                  itemprocon.item_id = item.item_id
                  itemprocon.article_content_id = content.id
                  itemprocon.proorcon = "Con"
                  itemprocon.text = con.strip
                  itemprocon.pro_con_category_id = tempid 
                  itemprocon.letters_count = con.length, 
                  itemprocon.words_count = con.scan(/\w+/).size
                  itemprocon.save
            end
        end
    end    
 
  end

  def save_content_relations_cache(related_items)
    new_records = []
    related_items.each do |item|
      new_records << ItemContentsRelationsCache.new(:item_id => item, :content_id => self.id)
    end
    ItemContentsRelationsCache.import(new_records)
  end

  def get_itemtype(item)
    item.get_base_itemtypeid()
  end

  def update_with_items!(params, items)
    item_type_ids = Array.new
    Content.transaction do
      self.status = get_content_status("update")
      self.update_attributes(params)
      ContentItemRelation.delete_all(["content_id = ?", self.id])
      rel_items = []

      page = 1
      sql_query = "select * from items where id in (#{items.split(",").map(&:inspect).join(',')})"
      begin
        items = Item.paginate_by_sql(sql_query, :page => page, :per_page => 1000)

        items.each_with_index do |item, index|
          unless item.blank?
            if index == 0
              itemtype_id_val = get_itemtype(item)
              if self.itemtype_id != itemtype_id_val
                self.update_attributes(:itemtype_id => itemtype_id_val)
              end
            end
            item_type_ids << get_itemtype(item)
            rel= ContentItemRelation.new(:item => item, :content => self, :itemtype => item.type)
            rel_items << rel
          end
        end

        ContentItemRelation.import(rel_items)

        ContentItemtypeRelation.delete_all(["content_id = ?", self.id])
        rel_type_items = []
        item_type_ids.uniq.each do |id|
          rel_type_item = ContentItemtypeRelation.new(:itemtype_id => id, :content_id => self.id)
          rel_type_items << rel_type_item
        end
        ContentItemtypeRelation.import(rel_type_items)

        page += 1
      end while !items.empty?
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

  def rating_classnames(user)
    unless(user.nil?)
    keyword_id = "votes_#{user.id}_list"
    vote_list = $redis.smembers "#{keyword_id}"
    class_type = get_class_name(self.class.name)
    value = vote_list.find {|s| s.to_s == "type_#{class_type}_voteableid_#{self.id}".to_s}
    reset = true
    unless value.nil?
      if  user.voted_positive?(self)
        negative_class = "btn_dislike_positive"
        positive_class = "btn_like_positive"
        reset = false
      end
      if user.voted_negative?(self)
        positive_class = "btn_like_negative"
        negative_class = "btn_dislike_negative"
        reset = false
      end
    end
    if reset == true
      positive_class = "btn_like_default"
      negative_class = "btn_dislike_default"    
    end
  else
      positive_class = "btn_like_default"
      negative_class = "btn_dislike_default"    
  end
    return self.id =>{:positive => positive_class, :negative => negative_class}

  end

  def remove_ad_item_ids_from_redis
    ad_key = "#{self.url}ad_or_widget_item_ids"
    widget_key = "#{self.url}ad_or_widget_item_ids"
    $redis.del(ad_key, widget_key)
  end

end
