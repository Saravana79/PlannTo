require 'json'
class Item < ActiveRecord::Base

  validates :name, :itemtype_id, :imageurl, :presence => true
  attr_accessor :old_version_id

  has_many :add_impressions
  has_many :impressions, :as=>:impressionable
  self.inheritance_column ='type'
  REDIS_FOLLOW_ITEM_KEY_PREFIX = "follow_item_user_ids_"
  #cache_records :store => :local, :key => "items",:request_cache => true
  FOLLOWTYPES = ["Car","Mobile","Cycle","Tablet","Bike","Camera","Manufacturer", "CarGroup", "Topic"]
  TOPIC_FOLLOWTYPES = ["Topic","AttributeTag"]
  ITEMTYPES = ["Car","Mobile","Cycle","Tablet","Bike","Camera","Manufacturer", "Car Group", "Topic"]
  belongs_to :itemtype
  has_one :item_rating
  has_one :vendor_detail
  has_many :itemdetails, :foreign_key => 'itemid'
  #  has_many :itemrelationships
  #  has_many :relateditems, :through => :itemrelationships
  #
  #  has_many :inverse_itemrelationships, :class_name => 'Itemrelationship', :foreign_key => 'relateditem_id'
  #  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :source => :item
  ##  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :
  has_many :item_contents_relations_cache, :class_name => "ItemContentsRelationsCache"
  has_many :shares # to be removed
  has_many :item_specification_summary_lists
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

  has_many :item_pro_cons
  has_one :item_ad_detail

  after_save :create_item_ad_detail
  after_save :update_redis_with_item

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
          unless item_attribute1.first.nil?
           price = item_attribute1.first.name + ' - '  +
          number_to_indian_currency(min_price.to_i) +
           '  -  ' +   number_to_indian_currency(max_price.to_i) +
          (attribute_value1.first.addition_comment.blank? ? "" : " ( #{attribute_value1.first.addition_comment} )")
          end 
         else
          unless item_attribute1.first.nil?
           price = item_attribute1.first.name + ' - '  +
          number_to_indian_currency(min_price.to_i) +
          (attribute_value1.first.addition_comment.blank? ? "" : " ( #{attribute_value1.first.addition_comment} )")
          end
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
  
  
  def get_launch_date
    date = Date.parse(self.attribute_values.select{|a| a.attribute_id == 8}.last.value) rescue ""
    return date if date == ""
    day = date.day  rescue ''
    if day == '' 
     return ''
    end 
    month = date.month.to_i - 1
    year = date.year
    months = ['January','February','March','April','May','June','July','August','September','October','November','December','']
    month = months[month]
    return "#{month}, #{year}" 
 end
  
  
  def get_price_info(item_type,displaycomment = true,buy_items_size=0 )
    price = "0"; 
    #item_attribute = item_attributes.select{|a| a.name == item_type}.last
    price_attribute = self.attribute_values.select{|a| a.attribute_id == 1}.last
      if (status == "1" || status == "3")
        if price_attribute
          attribute_value = price_attribute.value
          if !attribute_value.blank?
            if(displaycomment)
             if !(self.is_a?(Car) || self.is_a?(Bike)) && buy_items_size > 1
               "Price " + ' - '  +
              "Starting at <span id='item_price' style='cursor: pointer;'>" + number_to_indian_currency(attribute_value.to_i) + "</span>" +
              (price_attribute.addition_comment.blank? ? "" : " ( #{price_attribute.addition_comment} )")
             else
               "Price " + ' - '  +
               number_to_indian_currency(attribute_value.to_i)  +
              (price_attribute.addition_comment.blank? ? "" : " ( #{price_attribute.addition_comment} )") 
             end  
            else
            if !(self.is_a?(Car) || self.is_a?(Bike)) && buy_items_size > 1
              "Starting at <span id='item_price' style='cursor: pointer;'>" +  number_to_indian_currency(attribute_value.to_i)  + '</span>'
            else
               number_to_indian_currency(attribute_value.to_i)
            end    
            end 
          else
            ""
          end
        else
          ""
        end
      elsif status == "2"
        "[Not yet launched in India]"
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
    item_attributes.select("attributes.id as id,attribute_id, value, name, unit_of_measure, category_name, attribute_type, attributes.hyperlink as attributeshyperlink,attribute_values.hyperlink as valuehyperlink, description").order("attribute_id")
  end
  def get_name
    if((!alternative_name.nil?) && (!alternative_name.blank?))
      name + " / " + alternative_name
    else
      name
    end
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
  def base_item_image_url(imagetype = :medium)
        
      if(imagetype == :medium)
        configatron.root_image_url + self.type.downcase + '/medium/default_' + self.type.downcase + ".jpeg"
      elsif (imagetype == :org)
        configatron.root_image_url + self.type.downcase + '/org/default_' + self.type.downcase + ".jpeg"
      else   
         configatron.root_image_url + self.type.downcase + '/small/default_' + self.type.downcase + ".jpeg"
      end
  end

  def self.get_related_items(item, limit, includ=false)
    #unless includ
      related_item_ids = RelatedItem.where(:item_id => item.id).order("variance desc").collect(&:related_item_id)
    #else
    #  related_item_ids = item.itemrelationships.collect(&:relateditem_id)
    #end
    # related_item_ids = RelatedItem.where(:item_id => item.id).collect(&:related_item_id)
    if item.type == Itemtype::CAR
      items = Item.where(:id => related_item_ids,:itemtype_id => item.itemtype.id).order("id desc").limit(limit+15).uniq{|x| x.group_id} 
      unless(item.group_id.nil?)
        items = items.select{|a| (a.group_id.nil? or a.group_id != item.group_id) }
      end
      items = Item.where(:id => items[0..4].collect(&:id)).includes(:item_rating,:attribute_values)
    else
      # items = Item.where(:id => related_item_ids,:itemtype_id => item.itemtype.id).includes(:item_rating,:attribute_values).order("id desc").limit(limit+2)
      items = Item.find(related_item_ids, :order => "field(id, #{related_item_ids.map(&:inspect).join(',')})")
      items = items.select {|each_item| each_item.itemtype_id == item.itemtype_id}
      unless(item.group_id.nil?)
        items = items.select {|a| (a.group_id.nil? or a.group_id != item.group_id) }
      end
    end
    
    return items[0..4]
  end

  def self.get_related_item_list(item, limit=10, page=1) 
    logger.info "(((((((((((((((((((((((((((((("

   # return item.relateditems.paginate(:page => page, :per_page => limit)
   itemdetails = Item.find_by_id(item)
    if (itemdetails.is_a?AttributeTag)    
      Item.find_by_sql("SELECT distinct a.* from items AS a INNER JOIN attribute_values ON attribute_values.item_id = a.id  INNER JOIN item_attribute_tag_relations on attribute_values.attribute_id =item_attribute_tag_relations.attribute_id and  item_attribute_tag_relations.value = attribute_values.value  WHERE item_attribute_tag_relations.item_id = " + item.to_s + " order by a.created_at desc").paginate(:page => page, :per_page => limit)
    else
      related_item_ids = Itemrelationship.where(:relateditem_id => item).collect(&:item_id)
      Item.where(:id => related_item_ids).order("created_at desc").paginate(:page => page, :per_page => limit)
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
      top_contributors = ActiveRecord::Base.connection.execute("select * from view_top_contributors where item_id = #{self.id} ORDER BY points DESC limit 5")
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
  if !(self.item_rating.review_total_count rescue false)
      item_rating = self.rating
      return item_rating
    end
   return self.item_rating.review_total_count.to_i
  end  

  def rated_users_count_group
   if !(self.item_rating.review_total_count rescue false)
      item_rating = 0
      
      self.related_cars.each do |c|
        item_rating += c.rating
      end  
     return item_rating
   else
     return self.item_rating.review_total_count.to_i 
    end
   end
   
  def rating
    item_rating = self.item_rating.average_rating rescue 0.0
    roundoff_rating item_rating.to_f
  end 

  def rank
    item_rating = self.item_rating.rank rescue 0.0  
  end 

  def roundoff_rating item_rating
    ((item_rating * 2).round) / 2.0
  end

  def add_new_rating(content)
    
    self.update_ratings
    # if self.item_rating.nil? 
    #   prev_rating = "no"
    # else
    #   prev_rating = self.item_rating.average_rating.nil? ? 0.0 : self.item_rating.average_rating
    # end

    # if prev_rating == "no" && self.item_rating.nil?
    #   r = ItemRating.new
    #  if content.is_a?(ArticleContent) 
      
    #    r.expert_review_count = (content.field1.to_i == 0 || content.field1.nil?) ? 0 : 1
    #    r.expert_review_total_count = 1
    #    r.expert_review_avg_rating =   content.field1.to_f rescue 0.0
    #    r.average_rating = content.field1.to_f rescue 0.0
    #    r.review_count =  (content.field1.to_i == 0 || content.field1.nil?) ? 0 : 1
    #    r.review_total_count =   1
    #    r.item_id = self.id
    #    r.save
    #    return true
    # else
    #    r.user_review_count =  (content.rating.to_i == 0 || content.rating.nil?) ? 0 : 1
    #    r.user_review_total_count = 1
    #    r.user_review_avg_rating =   content.rating.to_f rescue 0.0
    #    r.average_rating = content.rating.to_f rescue 0.0
    #    r.review_count =   (content.rating.to_i == 0 || content.rating.nil?) ? 0 : 1
    #    r.review_total_count =   1 
    #    r.item_id = self.id
    #    r.save
    #    return true
    #  end 
     
    # else
    #   prev_review_count = self.item_rating.review_count.to_i
    #   prev_rating = prev_rating.to_f
    #   if content.is_a?(ReviewContent) &&  !(content.rating.to_i == 0 || content.rating.nil?)
    #     new_average_rating = ((prev_rating * prev_review_count) + content.rating.to_f) / (prev_review_count + 1).to_f rescue 0.0
    #     self.item_rating.review_count = prev_review_count + 1
    #   elsif content.is_a?(ArticleContent) && !(content.field1.to_i == 0 || content.field1.nil?)
    #      new_average_rating = ((prev_rating * prev_review_count) + content.field1.to_f) / (prev_review_count + 1).to_f rescue 0.0 
    #      self.item_rating.review_count = prev_review_count + 1
    #   end   

    #   self.item_rating.average_rating = new_average_rating if !new_average_rating.nil? || !new_average_rating.blank?
      
    #    if  content.is_a?(ReviewContent)
    #      self.item_rating.user_review_avg_rating =  ((self.item_rating.user_review_avg_rating *  self.item_rating.user_review_count) + content.rating.to_f rescue 0.0) / (self.item_rating.user_review_count + 1).to_f if  !(content.rating.to_i == 0 || content.rating.nil?) 
    #      self.item_rating.user_review_count = self.item_rating.user_review_count + ((content.rating.to_i == 0 || content.rating.nil?) ? 0 : 1).to_i 
    #      self.item_rating.user_review_total_count = self.item_rating.user_review_total_count + 1           
    #   else
    #     self.item_rating.expert_review_avg_rating =  (( self.item_rating.expert_review_avg_rating *  self.item_rating.expert_review_count) + content.field1.to_f rescue 0.0) / (self.item_rating.expert_review_count + 1).to_f if  !(content.field1.to_i == 0 || content.field1.nil?)               
    #     self.item_rating.expert_review_count = self.item_rating.expert_review_count + ((content.field1.to_i == 0 || content.field1.nil?) ? 0 : 1).to_i
    #     self.item_rating.expert_review_total_count = self.item_rating.expert_review_total_count + 1   
        
    #    end
    #    self.item_rating.save
    #  end
    #   prev_count_total = self.item_rating.review_total_count
    #   unless prev_count_total
    #     self.item_rating.update_attribute("review_total_count",1)
    #   else
    #     self.item_rating.update_attribute("review_total_count",prev_count_total + 1)
    #   end 

  end

  def update_remove_rating(rating,content,update=false)
      self.update_ratings
   #  prev_rating = self.item_rating.average_rating
   #  prev_review_count = self.item_rating.review_count.to_i
   #  prev_rating = prev_rating.to_f rescue 0.0
   #  if content.is_a?(ReviewContent) && !(rating.to_i == 0 || rating.nil? || prev_rating == 0.0)

   #    new_average_rating = ((prev_rating * prev_review_count) - rating) / (prev_review_count - 1).to_f rescue 0.0
  
   # elsif content.is_a?(ArticleContent)  && !(rating.to_i == 0 || rating.nil? || prev_rating == 0.0)
   #    new_average_rating = ((prev_rating * prev_review_count) - rating.to_f) / (prev_review_count - 1).to_f rescue 0.0 
   #  end  
   #   unless prev_review_count.to_i == 1  || prev_rating == 0.0
   #     self.item_rating.average_rating = new_average_rating if !new_average_rating.nil? || !new_average_rating.blank?
   #   else
   #     self.item_rating.average_rating = 0.0
   #   end    
   #      self.item_rating.review_count = prev_review_count - 1  if  !(rating.to_i == 0 || rating.nil? || prev_rating == 0.0)
   #      if  content.is_a?(ReviewContent)
   #        u_r_c = self.item_rating.user_review_count.to_i
   #        if  u_r_c!= 1
   #          if !(rating.to_i == 0 || rating.nil?)
   #            self.item_rating.user_review_avg_rating =  ((self.item_rating.user_review_avg_rating *  u_r_c) - rating.to_f rescue 0.0) / (u_r_c - 1).to_f  rescue 0.0 if  !(rating.to_i == 0 || rating.nil?) 
   #          end
   #       else
   #          self.item_rating.user_review_avg_rating = 0.0
   #       end    
   #        self.item_rating.user_review_count = u_r_c  - ((rating.to_i == 0 || rating.nil?) ? 0 : 1).to_i
   #        self.item_rating.user_review_total_count = self.item_rating.user_review_total_count - 1   
   #      else
   #       if self.item_rating.expert_review_count.to_i != 1
   #         if !(rating.to_i == 0 || rating.nil?)
   #          self.item_rating.expert_review_avg_rating =  (( self.item_rating.expert_review_avg_rating *  self.item_rating.expert_review_count) - rating rescue 0.0) / (self.item_rating.expert_review_count - 1).to_f rescue 0.0  if  !(rating.to_i == 0 || rating.nil?) 
   #         end
   #      else
   #        self.item_rating.expert_review_avg_rating  = 0.0
   #      end   
   #        self.item_rating.expert_review_count = self.item_rating.expert_review_count.to_i - ((rating.to_i == 0 || rating.nil?) ? 0 : 1).to_i
   #       self.item_rating.expert_review_total_count = self.item_rating.expert_review_total_count - 1   
   #    end
   #      self.item_rating.save
   #      prev_count_total = self.item_rating.review_total_count

   #    unless prev_count_total
   #       self.item_rating.update_attribute("review_total_count",1)
   #    else
   #      self.item_rating.update_attribute("review_total_count",prev_count_total - 1)
   #   end  
   #   if (update == true  && content.sub_type == "Reviews")
   #     self.add_new_rating(content)
   #   end
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
 
  def self.find_root_level_id(type,items)
    case type
    when 'Mobile'
      return (items + "," + configatron.root_level_mobile_id.to_s)
    when 'Camera'
      return (items + "," + configatron.root_level_camera_id.to_s)
    when 'Tablet' 
      return (items + "," +  configatron.root_level_tablet_id.to_s)
    when 'Bike'
      return (items + "," +  configatron.root_level_bike_id.to_s)
    when "CarGroup"
      return (items + "," + configatron.root_level_car_id.to_s)
    when "Car"
      return (items + "," + configatron.root_level_car_id.to_s)
    when "Manufacturer"
      return (items + "," +  configatron.root_level_car_id.to_s)
    when 'Cycle'
      return (items + "," +  configatron.root_level_cycle_id.to_s)
    when 'Laptop'
      return (items + "," +  configatron.root_level_laptop_id.to_s)
    when 'Game'
      return (items + "," +  configatron.root_level_game_id.to_s)
    when 'GamingConsole'
      return (items + "," +  configatron.root_level_game_id.to_s)
    end 
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
          items << configatron.root_level_bike_id.to_s
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

def update_ratings()
       item = self
        created_reviews = Array.new
        complete_created_reviews = item.contents.where("type = 'ReviewContent' and  status = 1")    
        complete_created_reviews.each do |rev|
           created_reviews << rev unless (rev.rating.to_i == 0 || rev.rating.nil?)
        end
        shared_reviews = Array.new
        complete_shared_reviews = item.contents.where("sub_type = 'Reviews' and type != 'ReviewContent' and status = 1" )   
        complete_shared_reviews.each do |rev|   
          shared_reviews << rev unless (rev.field1.to_i == 0 || rev.field1.nil?)
        end
        #return 0 if (created_reviews.empty? && shared_reviews.empty?)
        unless created_reviews.empty?
        created_avg_sum = created_reviews.inject(0){|sum,review| sum += review.rating.to_f} 
        else
            created_avg_sum = 0
        end
        unless shared_reviews.empty?
        shared_avg_sum = shared_reviews.inject(0){|sum,review| sum += review.field1.to_f}
        else
          shared_avg_sum = 0
        end
        if(created_avg_sum == 0 && shared_avg_sum == 0)
        
          item_rating =  0
        
        else
          rating = (created_avg_sum + shared_avg_sum)/(created_reviews.size.to_f + shared_reviews.size.to_f) rescue 0.0
         
        end  
        if (created_avg_sum == 0) || created_reviews.size == 0
           user_review_avg_rating = 0 
        else
            user_review_avg_rating = (created_avg_sum)/(created_reviews.size).to_f rescue 0.0
        end      
         
        if  shared_avg_sum == 0 || shared_reviews.size == 0  
            expert_review_avg_rating = 0
        else
           expert_review_avg_rating = (shared_avg_sum)/(shared_reviews.size).to_f rescue 0.0
        end    
      
         user_review_count = created_reviews.size
         expert_review_count = shared_reviews.size
         expert_review_total_count = complete_shared_reviews.size        
         user_review_total_count = complete_created_reviews.size
       
         average_rating = rating
         review_count =  user_review_count + expert_review_count
         review_total_count =   user_review_total_count   +      expert_review_total_count
         item_rating1 = ItemRating.find_by_item_id(item.id)
         if(item_rating1.nil?)
            item_rating1 = ItemRating.new
         end
           item_rating1.user_review_count = user_review_count
           item_rating1.expert_review_count = expert_review_count
           item_rating1.expert_review_total_count = expert_review_total_count      
           item_rating1.user_review_total_count = complete_created_reviews.size
           item_rating1.expert_review_avg_rating =  expert_review_avg_rating
           item_rating1.user_review_avg_rating = user_review_avg_rating
           item_rating1.average_rating = average_rating 
           item_rating1.review_count =  user_review_count + expert_review_count
           item_rating1.review_total_count =     review_total_count
           item_rating1.item_id = item.id
           item_rating1.save
      
  end

def can_display_related_item?
 return true if self.type == "CarGroup"
 return true if self.type == "Manufacturer"
 return true if self.type == "AttributeTag"
 return false
end

def populate_pro_con
 item = self
 contents = ArticleContent.find_by_sql("select ac.* from article_contents ac inner join contents c on c.id = ac.id inner join item_contents_relations_cache icc on icc.content_id = ac.id left outer join facebook_counts fc on fc.content_id = ac.id where icc.item_id = #{item.id} and c.sub_type = 'Reviews' and c.status = 1  order by (if(total_votes is null,0,total_votes) + like_count + share_count) desc" )
     last_index = 0
     contents.each do |content|
                   # count+=1
                    item_pro = item.item_pro_cons.where(:proorcon => "Pro")
                    item_con = item.item_pro_cons.where(:proorcon => "Con")
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
                 #   pros = content.field2 ? content.field2.split(/,|\.|;/) : []     
                 #   cons = content.field3 ? content.field3.split(/,|\.|;/) : []
                    last_index += 1
                    
                    pros.each do |pro|
                     unless (pro.length < 3 )      
                        if(pro.strip[0..2].downcase == "and")
                          pro = pro[4..-1]
                        else
                          pro = pro
                        end
                         pro = pro.capitalize
                         if item.itemtype.pro_con_categories.blank?
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Pro", pro.strip, pro_con_category_id: nil, text: pro.strip, index: last_index, proandcon: "Pro", letters_count: pro.length, words_count: pro.scan(/\w+/).size)
                         else
                              tempid =  nil
                              item.itemtype.pro_con_categories.order(:sort_order).each do |pcc|
                                   pro_con_category_id = pcc.id
                                   list = pcc.list.downcase.strip.gsub(", ","|").gsub(",","|")
                                   if(pro.downcase.match(/#{list}/))
                                        tempid = pcc.id
                                        break
                                   end
                                                                
                              end
                              ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Pro", pro.strip, pro_con_category_id: tempid , text: pro.strip, index: last_index, proandcon: "Pro", letters_count: pro.length, words_count: pro.scan(/\w+/).size) 
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
                             if item.itemtype.pro_con_categories.blank?
                                  ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Con", con.strip, pro_con_category_id: nil, text: con.strip, index: last_index, proandcon: "Con", letters_count: con.length, words_count: con.scan(/\w+/).size)
                             else
                                  tempid =  nil
                                  item.itemtype.pro_con_categories.each do |pcc|
                                       pro_con_category_id = pcc.id
                                       list = pcc.list.downcase.strip.gsub(", ","|").gsub(",","|")
                                      if(con.downcase.match(/#{list}/))
                                            tempid = pcc.id
                                            break
                                       end                                  
                                  end
                                   ItemProCon.find_or_create_by_item_id_and_article_content_id_and_proorcon_and_text(item.id, content.id, "Con", con.strip, pro_con_category_id: tempid, text: con.strip, index: last_index, proandcon: "Con", letters_count: con.length, words_count: con.scan(/\w+/).size) 
                             end
                        end
                    end    
               #end
          end

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
     @items = Item.find(ids)
     #item_ids.map{|id| @items << Item.find(id) rescue ""}
     return @items
  end

  def self.get_popular_items()
     ids = configatron.popular_cars.split(",") + configatron.popular_bikes.split(",") + configatron.popular_cycles.split(",") + configatron.popular_mobiles.split(",")  + configatron.popular_tablets.split(",") + configatron.popular_cameras.split(",")
     @items = Item.where("id in (?)",ids)
     return @items
  end

  def self.populate_slug()
     items = Item.find(:all, :conditions=>["slug is null"])
        items.each do |item|
          puts item.id
            item.save
        end
  end
  def self.update_rank()
      date_modifier = configatron.launch_date_modifier.to_s

    Itemtype.where("itemtype in ('Car','Mobile','Bike','Tablet','Camera','Cycle')").each do |itemtype|  
    
      item_type_id = itemtype.id.to_s
      total_rating_to_consider = configatron.retrieve(("rating_m_for_" + itemtype.itemtype.downcase).to_sym).to_s
      
      avearge_rating_of_average  =  ItemRating.find_by_sql("select avg(average_rating) as avg1 from item_ratings where item_id in (select id from items where itemtype_id = #{item_type_id}) and (average_rating is not null  or average_rating!=0)").first.avg1.to_s
         
      sql_for_max_average = "select calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + ") as final_rating from (select items.name,average_rating,review_count,
            (((review_count/(review_count + " + total_rating_to_consider + ")) * average_rating) + ((" + total_rating_to_consider + "/(review_count+" + total_rating_to_consider + "))*" + avearge_rating_of_average + ")) as calculated_rating ,
            (select value from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id limit 1) as launchdatemonth1,
            (select period_diff(date_format(now(), '%Y%m'), date_format(str_to_date(value,'%d-%M-%Y') , '%Y%m'))from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id limit 1) as launchdatemonth,
            period_diff(date_format(now(), '%Y%m'),date_format(items.created_at,'%Y%m')) as createddatedifference
            from item_ratings 
            inner join items on items.id = item_ratings.item_id where itemtype_id = " + item_type_id + " and average_rating != 0 
            ) as a
            order by final_rating desc limit 1"
      
      max_average_value = ItemRating.connection.select_value(sql_for_max_average).to_f.round(2).to_s
      sql_for_rank = "select item_ratings_id, name, calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + ") as final_rating ,
            ((calculated_rating - ((case when (launchdatemonth > 0 and launchdatemonth1 != '') then launchdatemonth else createddatedifference end) * "+ date_modifier + "))/"+ max_average_value +") * 100 as rank from (select item_ratings.id as item_ratings_id,items.name,average_rating,review_count,
            (((review_count/(review_count + " + total_rating_to_consider + ")) * average_rating) + ((" + total_rating_to_consider + "/(review_count+" + total_rating_to_consider + "))*" + avearge_rating_of_average + ")) as calculated_rating ,
            (select value from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id limit 1) as launchdatemonth1,
            (select period_diff(date_format(now(), '%Y%m'), date_format(str_to_date(value,'%d-%M-%Y') , '%Y%m'))from attribute_values av where av.attribute_id = 8 and av.item_id = item_ratings.item_id limit 1) as launchdatemonth,
            period_diff(date_format(now(), '%Y%m'),date_format(items.created_at,'%Y%m')) as createddatedifference
            from item_ratings 
            inner join items on items.id = item_ratings.item_id where itemtype_id = " + item_type_id + " and average_rating != 0 
            ) as a
            order by final_rating desc"

     temp_item_ratings = ItemRating.connection.select_all(sql_for_rank)
     temp_item_ratings.each do |temp_item_rating|
        temp_item_rating_id = temp_item_rating["item_ratings_id"]
        final_rating = temp_item_rating["final_rating"]
        rank = temp_item_rating["rank"]
        if(!rank.nil?)
          rank = rank.round
          if(rank > 100)
            rank = 100
          elsif (rank < 0)
            rank = 0
          end
        end

        item_rating = ItemRating.find(temp_item_rating_id)
        item_rating.final_rating = final_rating
        item_rating.rank = rank
        item_rating.save
     end

    end 


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
   
  def self.select_option_list 
   [['Select Product','']] + Item.all.map{|i|[ i.name, i.id]}
  end

  def self.update_item_details(log, batch_size=2000)
    # query_to_get_price_and_vendor_ids = "select itemid as item_id,min(price) price,group_concat(distinct(site)) as vendor_id, i.itemtype_id as item_type, i.type as type from
    #                                     itemdetails id inner join items i on i.id = id.itemid where id.status in (1,3) and site in (9861,9882,9874,9880) group by itemid"

    query_to_get_price_and_vendor_ids = "select type, itemid as item_id, min(price) as price, group_concat(site order by price) as vendor_id, group_concat(price order by price) as
                                         pricestring from (select itemid, site, min(price)  as price, type from itemdetails id inner join items i on id.itemid=i.id where id.status in (1,3) and iserror != 1 and site in
                                         (9861,9882,9874,9880)  group by itemid,site ) a group by itemid"
    # p_v_records = Item.find_by_sql(query_to_get_price_and_vendor_ids)

    log.debug "********** Started Updating Price and Vendor_id for Items **********"
    # log.debug "********** Found #{p_v_records.count} items for update price and vendor_ids **********"
    log.debug "\n"

    page = 1
    begin
      p_v_records = Item.paginate_by_sql(query_to_get_price_and_vendor_ids, :page => page, :per_page => batch_size)

      p_v_records.each do |each_rec|
        redis_key = "items:#{each_rec.item_id}"
        val_hash = each_rec.attributes.reject {|g| ['item_id', 'pricestring'].include?(g)}
        redis_values = val_hash

        related_item_ids = RelatedItem.where('item_id = ?', each_rec.item_id).limit(10).collect(&:related_item_id).join(",")

        pc_vendor_id = Item.get_pc_vendor_ids(each_rec)

        redis_values.merge!(:related_item_ids => related_item_ids, :pc_vendor_id => pc_vendor_id)

        redis_values = redis_values.flatten

        log.debug "Hash Key => #{redis_key}"
        log.debug "Hash value => #{redis_values}"
        log.debug "\n"

        # redis_values = val_hash.flatten

        $redis_rtb.HMSET(redis_key, redis_values)
      end
      page += 1
    end while !p_v_records.empty?

    log.debug "********** Completed Updating price and vendor_id for Items **********"
    log.debug "\n"

    update_item_details_with_ad_ids(log, nil, batch_size)
  end

  def self.get_pc_vendor_ids(each_rec)
    price = each_rec.price * 1.02

    vendor_ids = each_rec.vendor_id.split(',')
    pricestring = each_rec.pricestring.split(',').map(&:to_f)
    hash_val = Hash[vendor_ids.zip(pricestring)]
    is_price_non_zero = hash_val.values.map {|each_val| each_val > 0}
    if is_price_non_zero.include?(true)
      hash_val = hash_val.delete_if {|_,v| v == 0.0}
      hash_val = Hash[hash_val.sort_by {|_,v| v}]
      price = hash_val.values[0] * 1.02
    end
    pc_vendor_id = hash_val.select {|k, v| v <= price }.keys
    pc_vendor_id = pc_vendor_id.join(",")
  end

  def self.update_item_details_with_ad_ids(log, item_ids=nil, batch_size=2000)

    custom_query = "1=1"

    unless item_ids.blank?
      custom_query = "item_id in (#{item_ids})"
    end

    query_to_get_advertisement_details = "select item_id,group_concat(distinct(a.id)) as advertisement_id,group_concat(icc.content_id) as content_id from item_contents_relations_cache icc
    inner join advertisements a on a.content_id = icc.content_id
    where icc.content_id in (select id from contents where type ='AdvertisementContent') and a.status = 1 and date(a.start_date) <= NOW() and date(a.end_date) >= NOW()
    group by item_id"

    # adv_records = Item.find_by_sql(query_to_get_advertisement_details)

    log.debug "********** Started Updating advertisement_id for Items **********"
    # log.debug "********** Found #{adv_records.count} items for update advertisement_id **********"
    log.debug "\n"

    page = 1
    begin
      adv_records = Item.paginate_by_sql(query_to_get_advertisement_details, :page => page, :per_page => 2000)
      adv_records.each do |each_rec|
        redis_key = "items:#{each_rec.item_id}"
        redis_values = {:advertisement_id => each_rec.advertisement_id}.flatten

        log.debug "Hash Key => #{redis_key}"
        log.debug "Hash value => #{redis_values}"
        log.debug "\n"

        $redis_rtb.HMSET(redis_key, redis_values)
      end
      page += 1
    end while !adv_records.empty?

    log.debug "********** Completed Updating advertisement_id for Items **********"
    log.debug "\n"


  end

  def self.old_version_item_id(item_id=nil)
    old_version_item = Item.where(:new_version_item_id => item_id).last
    old_version_item.blank? ? nil : old_version_item.id
  end

  def self.process_and_get_where_to_buy_items(items, publisher, status)
    @tempitems = []
    @where_to_buy_items = []
    items.each do |item|
      @item = item
      unless publisher.nil?
        unless publisher.vendor_ids.nil? or publisher.vendor_ids.empty?
          vendor_ids = publisher.vendor_ids ? publisher.vendor_ids.split(",") : []
          exclude_vendor_ids = publisher.exclude_vendor_ids ? publisher.exclude_vendor_ids.split(",")  : ""
          where_to_buy_itemstemp = @item.itemdetails.includes(:vendor).where('site not in(?) && itemdetails.status in (?)  and itemdetails.isError =?', exclude_vendor_ids,status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
          where_to_buy_items1 = where_to_buy_itemstemp.select{|a| vendor_ids.include? a.site}.sort_by{|i| [vendor_ids.index(i.site.to_s),i.status,(i.price - (i.cashback.nil? ?  0 : i.cashback))]}
          where_to_buy_items2 = where_to_buy_itemstemp.select{|a| !vendor_ids.include? a.site}
        else
          exclude_vendor_ids = publisher.exclude_vendor_ids ? publisher.exclude_vendor_ids.split(",")  : ""
          where_to_buy_items1 = []
          where_to_buy_items2 = @item.itemdetails.includes(:vendor).where('site not in(?) && itemdetails.status in (?)  and itemdetails.isError =?', exclude_vendor_ids,status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')
        end
      else
        where_to_buy_items1 = []
        where_to_buy_items2 = @item.itemdetails.includes(:vendor).where('itemdetails.status in (?)  and itemdetails.isError =?',status,0).order('itemdetails.status asc, (itemdetails.price - case when itemdetails.cashback is null then 0 else itemdetails.cashback end) asc')

      end
      @where_to_buy_items = where_to_buy_items1 + where_to_buy_items2

      if(@where_to_buy_items.empty?)
        @tempitems << @item
      else
        break
      end
    end

    return @where_to_buy_items, @tempitems, @item
  end

  def self.get_show_item_count(items)
    return_val = 2
    items_count = items.count
    item_names = items.map(&:name)
    item_names.each_with_index do |_, index|
      count_val = items_count - index
      selected_items = item_names[0..count_val]
      if selected_items.join('').length <= 40
        return_val = selected_items.count
        break
      end
    end
    return return_val
  end

  def self.make_item_with_valid_details(items, publisher, status)
    ret_items = []
    item = items.first
    where_to_buy_items, tempitems, item = Item.process_and_get_where_to_buy_items(items, publisher, status)

    if where_to_buy_items.blank?
      new_version_item_by_current_item = item.new_version_item_id.blank? ? nil : Item.where(:id => item.new_version_item_id).last

      unless new_version_item_by_current_item.blank?
        new_where_to_buy_items, new_tempitems, new_item = Item.process_and_get_where_to_buy_items([new_version_item_by_current_item], publisher, status)
        unless new_where_to_buy_items.blank?
          ret_items = [new_version_item_by_current_item]
        end
      else
        current_item_ad_detail = item.item_ad_detail

        unless current_item_ad_detail.blank?
          new_version_item_by_current_item_ad_detail = current_item_ad_detail.new_version_id.blank? ? nil : Item.where(:id => current_item_ad_detail.new_version_id).last
          unless new_version_item_by_current_item_ad_detail.blank?
            new_where_to_buy_items, new_tempitems, new_item = Item.process_and_get_where_to_buy_items([new_version_item_by_current_item_ad_detail], publisher, status)
            unless new_where_to_buy_items.blank?
              ret_items = [new_version_item_by_current_item_ad_detail]
            end
          else
            old_version_item_by_current_item_ad_detail = current_item_ad_detail.old_version_id.blank? ? nil : Item.where(:id => current_item_ad_detail.old_version_id).last
            unless old_version_item_by_current_item_ad_detail.blank?
              new_where_to_buy_items, new_tempitems, new_item = Item.process_and_get_where_to_buy_items([old_version_item_by_current_item_ad_detail], publisher, status)
              unless new_where_to_buy_items.blank?
                ret_items = [old_version_item_by_current_item_ad_detail]
              end
            end
          end
        end
      end
    else
      ret_items = items
    end

    return ret_items
  end

  def self.get_items_by_item_ids(item_ids, url, itemsaccess, request, for_widget=false, sort_disable='false')
    new_item_access = itemsaccess
    tempurl = url
    @items = []
    unless (item_ids.blank?)
      new_item_access = "ItemId"
      if (for_widget == true && sort_disable == "true")
        @items = Item.find(item_ids, :order => "field(id, #{item_ids.map(&:inspect).join(',')})")
      else
        @items = Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{item_ids.map(&:inspect).join(',')}) order by case when impressions < 1000 then #{configatron.ectr_default_value} else i.ectr end DESC limit 15")
        @items = Item.where(:id => item_ids) if @items.blank?
      end
      url = url.blank? ? request.referer : url
    else
      unless $redis.get("#{url}ad_or_widget_item_ids").blank?
        # @items = Item.where("id in (?)", $redis.get("#{url}ad_or_widget_item_ids").split(","))
        redis_item_ids = $redis.get("#{url}ad_or_widget_item_ids").split(",")
        @items = Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{redis_item_ids.map(&:inspect).join(',')}) order by case when impressions < 1000 then #{configatron.ectr_default_value} else i.ectr end DESC limit 15")
      else
        unless url.nil?
          tempurl = url;
          if url.include?("?")
            tempurl = url.slice(0..(url.index('?'))).gsub(/\?/, "").strip
          end
          if url.include?("#")
            tempurl = url.slice(0..(url.index('#'))).gsub(/\#/, "").strip
          end
          @articles = ArticleContent.where(url: tempurl)

          if @articles.empty? || @articles.nil?
            #for pagination in publisher website. removing /2/
            tempstr = tempurl.split(//).last(3).join
            matchobj = tempstr.match(/^\/\d{1}\/$/)
            unless matchobj.nil?
              tempurlpage = tempurl[0..(tempurl.length-3)]
              @articles = ArticleContent.where(url: tempurlpage)
            end
          end

          unless @articles.empty?
            @items = @articles[0].allitems.select{|a| a.is_a? Product}
            article_items_ids = @items.map(&:id)
            new_items = article_items_ids.blank? ? nil : Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{article_items_ids.map(&:inspect).join(',')}) order by case when impressions < 1000 then #{configatron.ectr_default_value} else i.ectr end DESC limit 15")

            if !new_items.blank?
              @items = new_items
            end
            $redis.set("#{url}ad_or_widget_item_ids", @items.collect(&:id).join(",")) unless @items.blank?
          end
        end
      end
    end
    return @items, new_item_access, url, tempurl

  end

  def self.assign_template_and_item(ad_template_type, item_details, items, suitable_ui_size)
    if suitable_ui_size == "300_600"
      item_details = item_details.first(18)
      correct_count = item_details.count > 2 ? item_details.count - (item_details.count % 3) : item_details.count
      item_details = item_details.first(correct_count)
      sliced_item_details = item_details.each_slice(3)
    elsif ad_template_type == "type_2"
      item_details = item_details.first(12)
      sliced_item_details = item_details.each_slice(2)
    else
      item_details = item_details.first(6)
      sliced_item_details = []
    end

    # assign items
    if !items.blank?
      item = items.first
    elsif items.blank? && !item_details.blank?
      list_item_ids = item_details.map(&:itemid).uniq
      items = Item.where("id in (?)", list_item_ids)
      item = items.first
    end
    return item_details, sliced_item_details, item, items
  end

  def self.get_related_items_if_one_item(items, publisher, status)
    # check is there valid item_details
    get_items = Item.make_item_with_valid_details(items, publisher, status)
    items = get_items unless get_items.blank?
    item = items.first
    item_ad_detail = item.item_ad_detail
    # items = []
    unless item_ad_detail.blank?
      related_item_ids = item_ad_detail.related_item_ids.to_s.split(',')
      new_items = Item.find_by_sql("select items.* from items join item_ad_details i on i.item_id = items.id where items.id in (#{related_item_ids.map(&:inspect).join(',')})
                                    order by case when impressions < 1000 then #{configatron.ectr_default_value} else i.ectr end DESC limit 5") unless related_item_ids.blank?
      items << new_items

      items = items.flatten
    end
    items.compact
  end

  def self.get_item_ids_for_300_600()
    items = Item.find_by_sql("select * from item_ad_details  order by impressions desc limit 10")
    item_ids = items.map(&:id) - [0]
    return item_ids
  end

  private

  def create_item_ad_detail
    old_item = Item.where(:id => self.old_version_id).last

    unless old_item.blank?
      old_item.update_attributes!(:new_version_item_id => self.id)
      old_item_ad_detail = old_item.item_ad_detail
      if old_item_ad_detail.blank?
        ItemAdDetail.create(:item_id => old_item.id, :new_version_id => self.id) # old_item_ad_detail
      else
        old_item_ad_detail.update_attributes!(:new_version_id => self.id)
      end
      new_item_ad_detail = ItemAdDetail.find_or_initialize_by_item_id(:item_id => self.id) # new_item_ad_detail
      new_item_ad_detail.update_attributes(:old_version_id => old_item.id)
    end
  end

  def update_redis_with_item
    #$redis.HMSET("items:#{id}", "price", nil, "vendor_id", nil, "avertisement_id", nil, "type", type)
    related_item_ids = RelatedItem.where('item_id = ?', self.id).limit(10).collect(&:related_item_id).join(",")

    Resque.enqueue(UpdateRedis, "items:#{id}", "price", nil, "vendor_id", nil, "advertisement_id", nil, "type", type, "related_item_ids", related_item_ids, "new_version_item_id", new_version_item_id)
  end

 end

