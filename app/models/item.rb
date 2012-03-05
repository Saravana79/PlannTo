class Item < ActiveRecord::Base
  self.inheritance_column ='type'
  belongs_to :itemtype
#  has_many :itemrelationships
#  has_many :relateditems, :through => :itemrelationships
#
#  has_many :inverse_itemrelationships, :class_name => 'Itemrelationship', :foreign_key => 'relateditem_id'
#  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :source => :item
##  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :
   has_many :shares # to be removed
    has_many :content_item_relations
    has_many :contents, :through => :content_item_relations

  has_many :groupmembers, :class_name => 'Item'
  belongs_to :group,   :class_name => 'Item', :foreign_key => 'group_id'

  belongs_to :user, :foreign_key => 'created_by'
  has_many :attribute_values
  has_many :item_attributes, :class_name => 'Attribute', :through => :attribute_values, :source => :attribute
  has_many :reviews
  has_many :pros
  has_many :cons
  has_many :best_uses
  has_many :itemrelationships, :foreign_key => :item_id
  has_many :relateditems,
    :through => :itemrelationships
  
  scope :get_price_range, lambda {|item_ids| joins(:item_attributes).
      where("attribute_values.item_id in (?) and attributes.name = 'Price'", item_ids).
      select("min(CAST(value as SIGNED)) as min_value, max(CAST(value as SIGNED)) as max_value, attributes.unit_of_measure as measure_type, attribute_values.addition_comment as comment, attributes.name as name").
      group("attribute_id")
  }

  acts_as_followable
  acts_as_rateable

  searchable :auto_index => true, :auto_remove => true  do

    text :name, :boost => 4.0,  :as => :name_ac    
  end

  def get_price_info(item_type)    
    item_attribute = item_attributes.select{|a| a.name == item_type}.last
    if item_attribute
      attribute_value = item_attribute.attribute_values.where(:item_id => id).last
      if !attribute_value.blank?
        item_attribute.name + ' - ' + (item_attribute.unit_of_measure || "") + ' ' +
          attribute_value.value +
          (attribute_value.addition_comment.blank? ? "" : " ( #{attribute_value.addition_comment} )")
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

  def related_followers(follow_type)
    related_iteams = followers_by_type('User')
    unless follow_type.blank?
      related_iteams.where("follows.follow_type" => follow_type)
    else
      related_iteams.where("follows.follow_type" => [Follow::ProductFollowType::Buyer,
          Follow::ProductFollowType::Owner,
          Follow::ProductFollowType::Follow])
    end
  end

  def priority_specification
    specification.where(:priority => 1)
  end

  def specification
    item_attributes.select("attribute_id, value, name, unit_of_measure, category_name, attribute_type")
  end

  def image_url
    if type == "CarGroup"
      configatron.root_image_url + 'car' + '/' + imageurl
    else
      configatron.root_image_url + type.downcase + '/' + imageurl
    end
    
  end

  def self.get_related_items(item, limit)
    related_item_ids = RelatedItem.where(:item_id => item.id).collect(&:related_item_id)
    return self.where(:id => related_item_ids).uniq{|x| x.cargroup}.first(limit) if item.type == Itemtype::CAR
    return self.where(:id => related_item_ids).first(limit)
  end

  def self.get_cached(id)
    begin
      Rails.cache.fetch('item:'+ id.to_s) do
        where(:id => id).includes(:item_attributes).last
      end
    rescue
      where(:id => id).includes(:item_attributes).try(:last)
    end

  end

  def self.find_all_and_sort_by_items(ids)
    items = Item.find_all_by_id(ids)
    sorted_items = Array.new
    ids.each do |id|
      items.each do |item|
        if item.id.to_i == id.to_i
          sorted_items << item
          break
        end
      end
    end
    return sorted_items
  end

end
