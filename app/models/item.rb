require 'json'
class Item < ActiveRecord::Base
  has_many :impressions, :as=>:impressionable
  self.inheritance_column ='type'
  REDIS_FOLLOW_ITEM_KEY_PREFIX = "follow_item_user_ids_"
  #cache_records :store => :local, :key => "items",:request_cache => true
  FOLLOWTYPES = ["Car","Mobile","Cycle","Tablet","Bike","Camera","Manufacturer", "CarGroup", "Topic"]
  TOPIC_FOLLOWTYPES = ["Topic","AttributeTag"]
  ITEMTYPES = ["Car","Mobile","Cycle","Tablet","Bike","Camera","Manufacturer", "Car Group", "Topic"]
  belongs_to :itemtype
  
  #  has_many :itemrelationships
  #  has_many :relateditems, :through => :itemrelationships
  #
  #  has_many :inverse_itemrelationships, :class_name => 'Itemrelationship', :foreign_key => 'relateditem_id'
  #  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :source => :item
  ##  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :
  has_many :item_contents_relations_cache, :class_name => "ItemContentsRelationsCache"
  has_many :shares # to be removed
  has_many :content_item_relations
  has_many :contents, :through => :item_contents_relations_cache
  has_many :reports, :as => :reportable, :dependent => :destroy 
  has_many :groupmembers, :class_name => 'Item'
  belongs_to :group,   :class_name => 'Item', :foreign_key => 'group_id'

  belongs_to :user, :foreign_key => 'created_by'
  has_many :attribute_values
  has_many :item_attributes, :class_name => 'Attribute', :through => :attribute_values, :source => :attribute
  has_many :reviews
  has_many :pros
  has_many :cons
  has_many :best_uses
  has_many :field_values
  has_many :itemrelationships, :foreign_key => :item_id
  has_many :relateditems,
    :through => :itemrelationships

  # default_scope includes(:attribute_values)
  
  scope :get_price_range, lambda {|item_ids| joins(:item_attributes).
      where("attribute_values.item_id in (?) and attributes.name = 'Price'", item_ids).
      select("min(CAST(value as SIGNED)) as min_value, max(CAST(value as SIGNED)) as max_value, attributes.unit_of_measure as measure_type, attribute_values.addition_comment as comment, attributes.name as name").
      group("attribute_id")
  }

  acts_as_followable
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  # acts_as_rateable

#  searchable :auto_index => true, :auto_remove => true  do

#    text :name, :boost => 2.0,  :as => :name_ac    
#  end

  def get_base_itemtypeid
    itemtype_id = case self.type
    when "AttributeTag" then ItemAttributeTagRelation.where("item_id = ? ", self.id).first.try(:itemtype_id)
    when "Manufacturer" then 
        unless (self.itemrelationships.first.nil?) 
          self.itemrelationships.first.related_cars.itemtype_id  
        else 
          self.itemtype_id
        end
    when "CarGroup" then 
        unless (self.itemrelationships.first.nil?) 
          self.itemrelationships.first.related_cars.itemtype_id  
        else 
          self.itemtype_id
        end
    when "ItemtypeTag" then Itemtype.where("itemtype = ? ", self.name.singularize).first.try(:id)
    when "Topic" then TopicItemtypeRelation.find_by_item_id(self.id).itemtype_id
    else self.itemtype_id
    end
    return itemtype_id
  end
  
  def impression_count
    impressions.size
  end
  
  def get_base_itemtype

    itemtype_id = self.get_base_itemtypeid
    itemtype1 = Itemtype.find_by_id(itemtype_id).itemtype
    return itemtype1
  end
  
  def get_group_price_info(item_type,displaycomment = true)
     prices = []
     item_attribute1= []
     attribute_value1 = []
     self.related_cars.each do |item|  
       item_attribute =  item.item_attributes.select{|a| a.name == item_type}.last
       item_attribute1 <<   item_attribute 
       if item_attribute
         attribute_value =  item_attribute.attribute_values.where(:item_id => item.id).last
         attribute_value1 << attribute_value
       if !attribute_value.blank?  
           prices << attribute_value.value.to_i  if attribute_value.value.to_i > 0
         end   
       end 
      end  
    
      price1 = prices.sort {|a1,a2| a2<=>a1}
      min_price = price1.last
      max_price = price1.first
      price = "0"; 
      if !prices.blank?
        if(displaycomment)
         if prices.size > 1
           price = item_attribute1.first.name + ' - '  +
          number_to_indian_currency(min_price.to_i) +
           '  -  ' +   number_to_indian_currency(max_price.to_i) +
          (attribute_value1.first.addition_comment.blank? ? "" : " ( #{attribute_value1.first.addition_comment} )")
         else
           price = item_attribute1.first.name + ' - '  +
          number_to_indian_currency(min_price.to_i) +
          (attribute_value1.first.addition_comment.blank? ? "" : " ( #{attribute_value1.first.addition_comment} )")
         end   
        else
         if prices.size > 1
          price = number_to_indian_currency(min_price.to_i) +  ' - '  + number_to_indian_currency(max_price.to_i)
         else
            price = number_to_indian_currency(min_price.to_i)
          end   
        end 
      else
        ""
      end
  end
  
  def get_price_info(item_type,displaycomment = true,buy_items_size=0 )
      
    price = "0"; 
    item_attribute = item_attributes.select{|a| a.name == item_type}.last
   
    if item_attribute
      attribute_value = item_attribute.attribute_values.where(:item_id => id).last
      if !attribute_value.blank?
        if(displaycomment)
         if !(self.is_a?(Car) || self.is_a?(Bike)) && buy_items_size > 1
           item_attribute.name + ' - '  +
          "Starting at <span id='item_price' style='cursor: pointer;'>" + number_to_indian_currency(attribute_value.value.to_i) + "</span>" +
          (attribute_value.addition_comment.blank? ? "" : " ( #{attribute_value.addition_comment} )")
         else
            item_attribute.name + ' - '  +
           number_to_indian_currency(attribute_value.value.to_i)  +
          (attribute_value.addition_comment.blank? ? "" : " ( #{attribute_value.addition_comment} )") 
        end  
        else
        if !(self.is_a?(Car) || self.is_a?(Bike)) && buy_items_size > 1
          "Starting at <span id='item_price' style='cursor: pointer;'>" +  number_to_indian_currency(attribute_value.value.to_i)  + '</span>'
        else
           number_to_indian_currency(attribute_value.value.to_i)
        end    
        end 
      else
        ""
      end
    else
      ""
    end
  end

  def unfollowing_related_items(user, number)
    if user
      car_groups(1, false, 2).select{|item| !user.following?(item) }[0..number]
    else
      car_groups.limit(number)
    end
  end

  def get_followers(follow_type=nil)
      related_iteams = followers_by_type('User')
      unless follow_type.blank?
        unless related_items_get = $redis.hget("#{REDIS_FOLLOW_ITEM_KEY_PREFIX}#{id}", follow_type)
          related_iteams = related_iteams.where("follows.follow_type" => follow_type).map(&:id).join(",")
          $redis.hset("#{REDIS_FOLLOW_ITEM_KEY_PREFIX}#{id}", follow_type, related_iteams)
          related_iteams
        else
          related_items_get
        end
      else
          related_iteams.where("follows.follow_type" => [Follow::ProductFollowType::Buyer,
                                                         Follow::ProductFollowType::Owner,
                                                         Follow::ProductFollowType::Follow])
        end
  end

  def ger_followers_count_for_type(follow_type)
   Follow.where('follow_type =? and followable_id=? and followable_type =?', follow_type,self.id, self.itemtype.itemtype == 'Car Group' ? 'CarGroup' : self.itemtype.itemtype).count
  end 

  def priority_specification
    specification.where(:priority => 1)
  end

  def specification
    item_attributes.select("attribute_id, value, name, unit_of_measure, category_name, attribute_type, attributes.hyperlink as attributeshyperlink,attribute_values.hyperlink as valuehyperlink, description").order("attribute_id")
  end
  
 
  def image_url(imagetype = :medium)
    if(!imageurl.blank?)
      if(imagetype == :medium)
        configatron.root_image_url + type.downcase + '/medium/' + "#{imageurl}"
      elsif (imagetype == :org)
        configatron.root_image_url + type.downcase + '/org/' + "#{imageurl}"
      else   
         configatron.root_image_url + type.downcase + '/small/' + "#{imageurl}"
      end
   else
      baseitemtype = get_base_itemtype.downcase
        if(imagetype == :medium)
        configatron.root_image_url + baseitemtype + '/medium/default_' + baseitemtype + ".jpeg"
      elsif (imagetype == :org)
        configatron.root_image_url + baseitemtype + '/org/default_' + baseitemtype + ".jpeg"
      else   
         configatron.root_image_url + baseitemtype + '/small/default_' + baseitemtype + ".jpeg"
      end
   end
  end

  def self.get_related_items(item, limit)
    related_item_ids = RelatedItem.where(:item_id => item.id).collect(&:related_item_id)
    return self.where(:id => related_item_ids).uniq{|x| x.cargroup}.first(limit) if item.type == Itemtype::CAR
    return self.where(:id => related_item_ids).first(limit)
  end

  def self.get_related_item_list(item, limit=10, page=1)
   # return item.relateditems.paginate(:page => page, :per_page => limit)
   itemdetails = Item.find_by_id(item)
    if (itemdetails.is_a?AttributeTag)    
      Item.find_by_sql("SELECT distinct a.* from items AS a INNER JOIN attribute_values ON attribute_values.item_id = a.id  INNER JOIN item_attribute_tag_relations on attribute_values.attribute_id =item_attribute_tag_relations.attribute_id and  item_attribute_tag_relations.value = attribute_values.value  WHERE item_attribute_tag_relations.item_id = " + item.to_s).paginate(:page => page, :per_page => limit)
    else
      related_item_ids = Itemrelationship.where(:relateditem_id => item).collect(&:item_id)
      Item.where(:id => related_item_ids).paginate(:page => page, :per_page => limit)
    end
  end

    def self.get_related_item_list_first(item)
    
     itemdetails =  Item.find_by_sql("SELECT a.* from items AS a INNER JOIN attribute_values ON attribute_values.item_id = a.id  INNER JOIN item_attribute_tag_relations on attribute_values.attribute_id =item_attribute_tag_relations.attribute_id and  item_attribute_tag_relations.value = attribute_values.value  WHERE item_attribute_tag_relations.item_id = " + item.to_s)
     itemdetails.collect(&:id)
  
  end

  def self.get_cached(id)
    #begin
    #  Rails.cache.fetch('item:'+ id.to_s) do
    #    where(:id => id).includes(:item_attributes).last
    #  end
    #rescue
      where(:id => id).includes(:item_attributes)
    #end

  end

  def self.find_all_and_sort_by_items(ids)
    items = Item.where(:id => ids)
    sorted_items = Array.new
    ids.each do |id|
      unless id== ""
      items.each do |item|
        if item.id.to_i == id.to_i
          sorted_items << item
          break
        end
      end
      end
    end
    return sorted_items
  end
  def self.get_attribute_tags(ids)
    idstr= ids.is_a?(Array) ? ids.join(',') : ids
    items=Item.find_by_sql ['SELECT distinct b.id from items AS a
    INNER JOIN attribute_values ON attribute_values.item_id = a.id
    INNER JOIN item_attribute_tag_relations on attribute_values.attribute_id =item_attribute_tag_relations.attribute_id and  item_attribute_tag_relations.value = attribute_values.value 
    INNER JOIN items AS b on b.id=item_attribute_tag_relations.item_id and b.type="AttributeTag"
    WHERE item_attribute_tag_relations.itemtype_id = a.itemtype_id and a.id in (?)', idstr]
    items.map(&:id).to_a
  end
  
  def self.get_all_related_items_ids(ids)
    idstr= ids.is_a?(Array) ? ids.join('_') : ids
    redis_key = "related_items_#{idstr}"
    value = $redis.get redis_key
    if value.nil?
    items = Item.find_all_by_id(ids)
    items_array=[]
    items.each do |item|
      #Parent Items
      ritems=item.itemrelationships.map(&:relateditem_id).to_a
      #Child Items
      citems=Itemrelationship.all(:conditions => {:relateditem_id => item.id}).map(&:item_id).to_a
      items_array.concat(ritems)
      items_array.concat(citems)
    end
    #Attribute Tags
    tags=Item.get_attribute_tags(ids)
    items_array.concat(tags)

    #ItemType Tags
    itypes = items.map(&:type).map(&:pluralize).uniq
    itags = Item.where(:name => itypes, :type => "ItemtypeTag").map(&:id).to_a
    items_array.concat(itags)

    if ids.is_a?(Array)
      items_array.concat(ids).uniq
    else
      items_array << ids
      items_array.uniq
    end
    $redis.set(redis_key,items_array.to_json)
  else
    items_array=JSON.parse(value)
  end
  return items_array
  end

  def get_top_contributors
    keyword_id = "items_#{self.id}_top_contributors"
    top_contributors = $redis.smembers "#{keyword_id}"
    if top_contributors.size == 0
      #query to find top contributors
      top_contributors = ActiveRecord::Base.connection.execute("select * from view_top_contributors where item_id = #{self.id} limit 5")
      #save in cache
      $redis.multi do
        top_contributors.each do |cont|
          user = User.find_by_id(cont[0])
          avatar_url =  user.get_photo(:thumb)
          userurl = user.get_url()
          #$redis.hmset "#{keyword_id}", "user_id", cont[0], "points", cont[2]
          $redis.sadd "#{keyword_id}", "#{cont[0]}@#{cont[2]}@#{user.name}@#{avatar_url}@#{userurl}"
          #$redis.sadd "#{keyword_id}", {:user_id => cont[0], :points => cont[2], :name => user.name, :avatar_url => avatar_url} #"#{cont[0]}_#{cont[2]}"
        end
      end
      top_contributors = $redis.smembers "#{keyword_id}"
    end
    return top_contributors
  end

  def rated_users_count
    unless($redis.hget("items:ratings", "item:#{self.id}:review_count_total"))
      item_rating = self.average_rating
    end
   return ($redis.hget("items:ratings", "item:#{self.id}:review_count_total")).to_i
  end  

  def rated_users_count_group
   unless($redis.hget("items:ratings1", "item:#{self.id}:review_count_total1"))
      item_rating = 0
      
      self.related_cars.each do |c|
        item_rating += c.average_rating
      end  
     return item_rating
   else
     return ($redis.hget("items:ratings1", "item:#{self.id}:review_count_total1")).to_i 
    end
   end
   
  def average_rating
  created_reviews = Array.new
    complete_created_reviews = self.contents.where(:type => 'ReviewContent' )    
    complete_created_reviews.each do |rev|
    created_reviews << rev unless (rev.rating.to_i == 0 || rev.rating.nil?)
    end
    shared_reviews = Array.new
    complete_shared_reviews = self.contents.where("sub_type = '#{ArticleCategory::REVIEWS}' and type != 'ReviewContent'" )   
    complete_shared_reviews.each do |rev|   
    shared_reviews << rev unless (rev.field1.to_i == 0 || rev.field1.nil?)
    end
    return 0 if (created_reviews.empty? && shared_reviews.empty?)
    unless created_reviews.empty?
    created_avg_sum = created_reviews.inject(0){|sum,review| sum += review.rating} 
    else
      created_avg_sum = 0
    end
    unless shared_reviews.empty?
    shared_avg_sum = shared_reviews.inject(0){|sum,review| sum += review.field1.to_i}
    else
      shared_avg_sum = 0
    end
    if(created_avg_sum == 0 && shared_avg_sum == 0)
      item_rating =  0
    else
       item_rating = (created_avg_sum + shared_avg_sum)/(created_reviews.size.to_f + shared_reviews.size.to_f)
    end
     $redis.hset("items:ratings", "item:#{self.id}:rating",item_rating) if item_rating  > 0
     $redis.hset("items:ratings", "item:#{self.id}:review_count",(created_reviews.size.to_f + shared_reviews.size.to_f)) if item_rating  > 0
     $redis.hset("items:ratings", "item:#{self.id}:review_count_total",(complete_shared_reviews.size.to_f + complete_created_reviews.size.to_f))
     return item_rating
    #reviews = self.contents.where("(type =:article_content and (field1 != null or field1 != 0)) or type = :review_content ", {:article_content => 'ArticleContent',:review_content =>'ReviewContent'})
   end 

  def rating
    unless item_rating = $redis.hget("items:ratings", "item:#{self.id}:rating")
      item_rating = self.average_rating
    end  
    roundoff_rating item_rating.to_f
  end 

  def roundoff_rating item_rating
    ((item_rating * 2).round) / 2.0
  end

  def add_new_rating rating
    prev_rating = $redis.hget("items:ratings", "item:#{self.id}:rating")
    unless prev_rating
      $redis.hset("items:ratings", "item:#{self.id}:rating",rating)
      $redis.hset("items:ratings", "item:#{self.id}:review_count",1)
      
    else
      prev_review_count = ($redis.hget("items:ratings", "item:#{self.id}:review_count")).to_i
      prev_rating = prev_rating.to_f
      new_average_rating = ((prev_rating * prev_review_count) + rating) / (prev_review_count + 1).to_f rescue 0.0
      $redis.hset("items:ratings", "item:#{self.id}:rating",new_average_rating)
      $redis.hset("items:ratings", "item:#{self.id}:review_count",prev_review_count + 1)      
    end
      prev_count_total = $redis.hget("items:ratings", "item:#{self.id}:review_count_total")
      unless prev_count_total
        $redis.hset("items:ratings", "item:#{self.id}:review_count_total",1)
      else
        $redis.hset("items:ratings", "item:#{self.id}:review_count_total",prev_count_total.to_i + 1)
      end  
  end

  def itemtypetag
    Item.find(:first,:conditions =>{:name => self.type.pluralize, :type => "ItemtypeTag"})
  end
  
  def related_content
    itemtypetag=self.itemtypetag
    attribute_tags=Item.get_attribute_tags(id).join(",")
    manufacturer=self.manufacturer if self.respond_to?(:manufacturer)
    cargroup=self.cargroup if self.respond_to?(:cargroup)

    sql  =   "Select content_id from content_item_relations where item_id = #{self.id}"
    unless attribute_tags.blank?
    #  sql +=  itemtypetag.get_hierarchy_sql(attribute_tags) unless itemtypetag.blank?
      sql +=  manufacturer.get_hierarchy_sql(attribute_tags,"'CarGroup','BikeGroup','AttributeTag'") unless manufacturer.blank?
      sql +=  cargroup.get_hierarchy_sql(attribute_tags,"'AttributeTag'") unless cargroup.blank?
      sql += " Union
      Select content_id from content_item_relations where content_id not in (select content_id from content_item_relations where content_id in     (select content_id from content_item_relations where item_id in (#{attribute_tags}) ) and itemtype in ('ItemTypeTag','Manufacturer','CarGroup','BikeGroup')) and item_id in (#{attribute_tags})"  unless attribute_tags.blank?
    end
    items=Item.find_by_sql(sql)
    items.map(&:content_id).to_a
  end

  def related_content_from_cache
    self.item_contents_relations_cache.collect(&:content_id)
  end
  
  def get_hierarchy_sql(attribute_tags,itemtypes="'Manufacturer','CarGroup','BikeGroup','AttributeTag'")
    " 
    Union
    Select content_id from content_item_relations where content_id not in (select  content_id from content_item_relations where content_id in (select content_id from content_item_relations where item_id = #{self.id}) and itemtype  in (#{itemtypes})) and item_id = #{self.id}
     Union
      Select content_id from content_item_relations where content_id in (select content_id from content_item_relations where item_id = #{self.id}) and item_id in (#{attribute_tags})"
  end

 def self.get_related_content_for_items(ids)
   contents =[]
   idstr= ids.is_a?(Array) ? ids.join(',') : ids
   redis_key = "related_content_#{idstr}"
   #value = $redis.get redis_key
   value = nil
   if value.nil?
   items = Item.find_all_by_id(ids)
   items.each do |item|
     contents.concat(item.related_content_from_cache.to_a)
   end
   contents=contents.uniq
   $redis.set(redis_key,contents.to_json)
 else
   contents=JSON.parse(value)
  end
  contents
 end

 def self.get_follows_item_ids_for_user_and_item_types(user,item_type_ids)
   item_types = Itemtype.where('id in (?)',item_type_ids).map{|i| i.itemtype == "Car Group" ? "CarGroup" : i.itemtype}
  @item,@root_items = Item.find_top_level_item_ids(item_types,user)
 end
 
 def self.find_top_level_item_ids(types,user)
     root_items = []
     items = []
     types.each do | type|
        
       it = [] 
       it+= Follow.where('follower_id =? and followable_type in (?)',user.id,type).collect(&:followable_id).uniq
      
       unless it.blank?
         case type
         when 'Mobile' 
          root_items<<  configatron.root_level_mobile_id.to_s
          items+= it
        
         when 'Camera'
          root_items<< configatron.root_level_camera_id.to_s
          items+= it
         
        when 'Tablet' 
          root_items << configatron.root_level_tablet_id.to_s
          items+= it
        
        when 'Bike'
          items << configatron.root_level_tablet_id.to_s
          items+= it
        when "CarGroup"
          root_items << configatron.root_level_car_id.to_s
          it.each do |i|
           object = Item.find(i)
           items+= object.related_cars.collect(&:id)
          end 
        when "Car"
          root_items << configatron.root_level_car_id.to_s
          items+= it
        when "Topic"
          items+= it        
        when "Manufacturer"
          root_items << configatron.root_level_car_id.to_s  
          it.each do |i|
           object = Item.find(i)
           items+= object.related_cars.collect(&:id)
         end 
        when 'Cycle'
           root_items <<  configatron.root_level_cycle_id.to_s 
           items+= it
         end
         end 
         end
        @items = items.uniq  
         return @items,root_items.uniq       
      end

  def self.get_follows_items_for_user(user) 
    Follow.where('follower_id =? and followable_type in (?) and follow_type =?',user.id,Item::FOLLOWTYPES,"follower").limit(5).map{|f| Item.find(f.followable_id)}
  end
  
  def self.get_total_follows_items_for_user(user) 
    Follow.where('follower_id =? and followable_type in (?)',user.id,Item::FOLLOWTYPES).limit(5).map{|f| Item.find(f.followable_id)}
  end
  def self.get_buyer_items_for_user(user) 
     Follow.where('follower_id =? and followable_type in (?) and follow_type =?',user.id,Item::FOLLOWTYPES,"buyer").limit(5).map{|f| Item.find(f.followable_id)}
  end
  
  
  def self.get_owned_items_for_user(user) 
    Follow.where('follower_id =? and followable_type in (?) and follow_type =?',user.id,Item::FOLLOWTYPES,"owner").limit(5).map{|f| Item.find(f.followable_id)}
  end
  def self.get_buyer_item_ids_for_user(user)
     popular_item_ids = configatron.wizard_items_buyer.split(",") 
     Follow.where('follower_id =? and follow_type =?',user.id,"buyer").collect(&:followable_id).collect{|i| i.to_s} - popular_item_ids
  end
  
  
  def self.get_owner_item_ids_for_user(user,type='nil')
     popular_item_ids = configatron.wizard_items_owner.split(",")
    if type == "all"  
      Follow.where('follower_id =? and follow_type =?',user.id,"owner").collect(&:followable_id).collect{|i| i.to_s}
    else  
       Follow.where('follower_id =? and follow_type =?',user.id,"owner").collect(&:followable_id).collect{|i| i.to_s}  - popular_item_ids
    end   
  end
  
  def self.get_topics_follower_ids_for_user(user,type='nil')
      popular_topic_ids = configatron.wizard_topics.split(",")
    if type == "all"
       Follow.where('follower_id =? and  follow_type =? and followable_type in (?)',user.id,"follower",Item::TOPIC_FOLLOWTYPES).collect(&:followable_id).collect{|i| i.to_s} 
    else      
     Follow.where('follower_id =? and  follow_type =? and followable_type in (?)',user.id,"follower",Item::TOPIC_FOLLOWTYPES).collect(&:followable_id).collect{|i| i.to_s} - popular_topic_ids
   end  
  end
  
 def show_specification
   has_specificiation = true
 end 

def show_buytheprice
  has_buytheprice = true
end 


def show_models
  has_models = false
end

def can_display_related_item?
 return true if self.type == "CarGroup"
 return true if self.type == "Manufacturer"
 return true if self.type == "AttributeTag"
 return false
end

  def number_to_indian_currency(number)
    if number
      string = number.to_s
      number = string.to_s.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/, "\\1,")    
    end
    "Rs #{number}"
  end
  
 
 def get_url()
   if (self.is_a? ItemtypeTag)
    "/#{self.name.downcase.pluralize}"
   elsif (self.is_a? CarGroup)
    "/groups/#{self.slug.to_s}"
   elsif (self.is_a? AttributeTag)
    "/groups/#{self.slug.to_s}"
   else
    "/#{self.type.downcase.pluralize}/#{self.slug.to_s}"
   end
end

  def self.popular_items(item_t,display_count=:Ten)
    case item_t.to_s
    when "Car"
      ids = configatron.popular_cars.split(",")
    when "Bike"
      ids = configatron.popular_bikes.split(",") 
    when "Cycle"
      ids = configatron.popular_cycles.split(",") 
    when "Mobile"
       ids = configatron.popular_mobiles.split(",")  
    when "Tablet"
      ids = configatron.popular_tablets.split(",")
    when "Camera"
       ids = configatron.popular_cameras.split(",")
    end      
    if display_count == :Ten
      item_ids = ids
    else
      count = configatron.popular_count.to_i - 1
      item_ids =  ids[0.."#{count}".to_i] #5 items display
    end
     @items = []
     item_ids.map{|id| @items << Item.find(id) rescue ""}
     return @items
  end
  
  def self.new_wizard_popular_topics_and_items(current_user,type)
   if type=="buyer"
     @items_buyer = []
     popular_item_buyer_ids = configatron.wizard_items_buyer.split(",")
     popular_item_buyer_ids.map{|id| @items_buyer  << Item.find(id) rescue ""}
     @items_owner = ""
     @topics = ""
   elsif type == "owner"
     @items_owner = []
     popular_item_owner_ids = configatron.wizard_items_owner.split(",")
     popular_item_owner_ids.map{|id| @items_owner  << Item.find(id) rescue ""}
     @topics = ""
     @items_buyer = ""
    elsif type == "follower"
     @topics = [] 
     popular_topic_ids = configatron.wizard_topics.split(",")
     popular_topic_ids.map{|id| @topics  << Item.find(id) rescue ""}
     @items_buyer = ""
     @items_owner = ""
    end   
    return @items_owner,@items_buyer,@topics
  end
      
  def self.popular_topics(item_t)
    case item_t.to_s
    when "Car"
      ids = configatron.popular_car_topics.split(",")
    when "Bike"
      ids = configatron.popular_bike_topics.split(",") 
    when "Cycle"
      ids = configatron.popular_cycle_topics.split(",") 
    when "Mobile"
       ids = configatron.popular_mobile_topics.split(",")  
    when "Tablet"
      ids = configatron.popular_tablet_topics.split(",")
    when "Camera"
       ids = configatron.popular_camera_topics.split(",")
    end  
     @items = []
     ids.map{|id| @items << Item.find(id) rescue ""}
     return @items    
    
  end
  def self.get_root_level_id(item_type)
    case item_type
    when "Car"
       return configatron.root_level_car_id
    when "Mobile"
       return configatron.root_level_mobile_id  
    when "Tablet"
       return configatron.root_level_tablet_id 
    when "Cycle"
       return configatron.root_level_cycle_id
    when "Bike"
       return configatron.root_level_bike_id   
    when "Camera"
       return configatron.root_level_camera_id 
    end 
   end           
 end

