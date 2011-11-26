class Item < ActiveRecord::Base
  belongs_to :itemtype
#  has_many :itemrelationships
#  has_many :relateditems, :through => :itemrelationships
#
#  has_many :inverse_itemrelationships, :class_name => 'Itemrelationship', :foreign_key => 'relateditem_id'
#  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :source => :item
##  has_many :inverse_relateditems, :through => :inverse_itemrelationships, :
  
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



  searchable :auto_index => true, :auto_remove => true  do

    text :name, :boost => 4.0,  :as => :name_ac    
  end

  def get_price_info(item_type)    
    item_attribute = item_attributes.first{|a| a.name == item_type}
    if item_attribute
      attribute_value = item_attribute.attribute_values.where(:item_id => id).last
      item_attribute.name + ' - ' + item_attribute.unit_of_measure + ' ' +
        attribute_value.value + ' ( ' + attribute_value.addition_comment + ' )'
    else
      ""
    end
  end

  def unfollowing_related_items(user, number)
    if user
      car_groups.select{|item| !user.following?(item) }[0..number]
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

end