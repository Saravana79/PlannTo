# To change this template, choose Tools | Templates
# and open the template in the editor.

class Product < Item

has_one :itemrelationship, :foreign_key => :item_id
has_many :itemrelationships, :foreign_key => :item_id

has_one :manufacturer,
        :through => :itemrelationship
#        :conditions => {'relationtype' => 'Manufacturer'}
#        :class_name => 'Manufacturer',
#        :source => :manufacturer
  has_one :cargroup, :through => :itemrelationship, :source => :cargroup



 def self.search_type(type)
   return [ "ItemtypeTag".camelize.constantize, "AttributeTag".camelize.constantize,"Topic".camelize.constantize,"Manufacturer".camelize.constantize, "CarGroup".camelize.constantize,"Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Game".camelize.constantize,"Laptop".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] if (type == "" || type == "Others" || type.nil?)
  if type.is_a?(Array)
    return type.collect{|t| t.camelize.constantize}
  else
    return type.camelize.constantize
  end
 end

def self.follow_search_type(type)
  if  type == "owner" || type == "buyer"
     return ["Car".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] 
  elsif  type == "follower"
    return ["AttributeTag".camelize.constantize,"Topic".camelize.constantize]
  elsif  type == "profile_follower"
     return ["Car".camelize.constantize,"AttributeTag".camelize.constantize,"Topic".camelize.constantize, "Tablet".camelize.constantize, "Mobile".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize]
    end      
end

def manu
    self.manufacturer
end


  def self.get_search_items_by_relavance(param, itemtypes=nil)
    unless param[:category].blank?
      itemtypes = param[:category].split(',')
    end
    search_type = Product.search_type(itemtypes)

    term = param[:term]

    removed_keywords = ["review", "how", "price", "between", "comparison", "vs", "processor", "display", "battery", "features", "india", "released", "launched",
                        "release", "limited", "period", "offer", "deal", "first", "impressions", "available", "online", "android", "video", "hands on", "hands-on"]
    term = term.split.delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')

    @items = Sunspot.search(search_type) do
      keywords term do
        minimum_match 1
      end
      order_by :score,:desc
      order_by :orderbyid , :asc
      paginate(:page => 1, :per_page => 5)
    end

    results = @items.results.collect{|item|

      image_url = item.image_url(:small)

      if(item.is_a? (Product))
        type = item.type.humanize
      elsif(item.is_a? (CarGroup))
        type = "Groups"
      elsif(item.is_a? (AttributeTag))
        type = "Groups"
      elsif(item.is_a? (ItemtypeTag))
        type = "Topics"
      else
        type = item.type.humanize
      end

      # end
      url = item.get_url()
      # image_url = item.image_url
      {:id => item.id, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
    }

    # Append suggestions based on category

    unless param[:category].blank?
      categories = param[:category].split(",")
      categories.each do |each_category|
        name, id = Item.find_root_level_id(each_category, each_category.pluralize).to_s.split(",")
        results << {:id => id, :value => name, :imgsrc =>"", :type => "Groups", :url => "" }
      end
    end

    items_by_score = {}
    @items.hits.map {|dd| items_by_score.merge!("#{dd.result.id}" => dd.score) if dd.score > 0.5}
    selected_list = Hash[items_by_score.sort_by {|k,v| v}].keys.reverse.first(2)

    return results, selected_list
  end

end
