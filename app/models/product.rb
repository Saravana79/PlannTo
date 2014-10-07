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
   return [ "ItemtypeTag".camelize.constantize, "AttributeTag".camelize.constantize,"Topic".camelize.constantize,"Manufacturer".camelize.constantize, "CarGroup".camelize.constantize,"Mobile".camelize.constantize, "Tablet".camelize.constantize, "Car".camelize.constantize, "Camera".camelize.constantize,"Game".camelize.constantize,"GamingConsole".camelize.constantize,"Console".camelize.constantize,"WearableGadget".camelize.constantize,"Laptop".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize,"Tablet".camelize.constantize,"Hotel".camelize.constantize,"City".camelize.constantize] if (type.blank? || type.include?("Others"))
  if type.is_a?(Array)
    return type.collect{|t| t.to_s.gsub(/\s+/,'').strip.camelize.singularize.constantize}
  else
    return type.to_s.gsub(/\s+/,'').strip.camelize.singularize.constantize
  end
 end

def self.follow_search_type(type)
  if  type == "owner" || type == "buyer"
     return ["Mobile".camelize.constantize, "Tablet".camelize.constantize, "Car".camelize.constantize, "Camera".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize] 
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
                        "release", "limited", "period", "offer", "deal", "first", "impressions", "available", "online", "android", "video", "hands on", "hands-on","bangalore", "hyderabad", "chennai","mumbai","and","delhi","valid"]
    term = term.to_s.split.delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')
    term = term.gsub("-","")
    @items = Sunspot.search(search_type) do
      keywords term do
        minimum_match 1
      end
      order_by :score,:desc
      order_by :orderbyid , :asc
      paginate(:page => 1, :per_page => 5)
    end

    items = @items.results
    results = Product.get_results_from_items(items)

    # Append suggestions based on category
    categories = []

    unless param[:category].blank?
      if param[:category] == "Others"
        categories = ["Mobile", "Tablet", "Camera", "Games", "Laptop", "Car", "Bike", "Cycle"]
      else
        categories = param[:category].split(",")
      end
      categories.each do |each_category|
        name, id = Item.find_root_level_id(each_category, each_category.pluralize).to_s.split(",")
        results << {:id => id, :value => name, :imgsrc =>"", :type => "Groups", :url => "" }
      end
    end

    if categories.include?('Mobile')
      app_items = ItemtypeTag.where("name = 'App'")
      app_results = Product.get_results_from_items(app_items)
      results << app_results
      results.flatten!
    end

    # items_by_score = {}
    # @items.hits.map {|dd| items_by_score.merge!("#{dd.result.id}" => dd.score) if dd.score.to_f > 0.5}
    all_items_by_score = {}
    @items.hits.map {|dd| all_items_by_score.merge!("#{dd.result.id}" => dd.score)}
    items_by_score = all_items_by_score.select {|key,val| val.to_f > 0.5}
    sorted_hash = Hash[items_by_score.sort_by {|k,v| v}]
    selected_list = sorted_hash.keys.reverse.first(2)

    if param[:ac_sub_type] == "Lists"
      selected_list = []
    elsif param[:ac_sub_type] != "Comparisons"
      selected_list = selected_list.first(1)
    end

    groups = []
    new_selected_list = []
    selected_items = items.select {|each_item| selected_list.include?(each_item.id.to_s)}
    selected_items.each_with_index do |each_selected_item, index|
      group = each_selected_item.cargroup rescue nil
      unless group.blank?
        groups << group
        new_selected_list << group.id.to_s
      else
        if ["Reviews", "Comparisons", "Spec"].include?(param[:ac_sub_type])
          new_selected_list << each_selected_item.id.to_s if (each_selected_item.is_a?(Product) || each_selected_item.is_a?(CarGroup))
        else
          new_selected_list << each_selected_item.id.to_s
        end
      end
    end
    new_results = Product.get_results_from_items(groups)
    results << new_results
    results.flatten!
    new_selected_list.uniq!

    all_items_by_score.each {|key,val| all_items_by_score[key] = val.round(2)}
    all_items_by_score.default = 0
    results.each {|each_result| each_result.merge!(:score => all_items_by_score[each_result[:id]])}
    list_scores = sorted_hash.select {|key,_| new_selected_list.include?(key)}.values.reverse.map {|each_val| each_val.round(2)}

    return results, new_selected_list, list_scores
  end

  def self.get_results_from_items(items)
    results = items.collect{|item|

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
      {:id => item.id.to_s, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
    }

    return results
  end

end
