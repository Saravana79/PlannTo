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

  def self.call_search_items_by_relavance(param, itemtypes=nil)
    if param[:term].downcase.include?("vs") && param[:ac_sub_type] == "Comparisons"
      f_results = []
      f_new_selected_list = []
      f_list_scores = []
      f_auto_save = []

      title = param[:term]
      split_title = title.downcase.split("vs").map(&:strip)
      split_title.each do |each_title|
        changed_param = param
        changed_param[:term] = each_title
        results, selected_list, list_scores, auto_save = Product.get_search_items_by_relavance(changed_param, itemtypes, for_compare="true")

        f_results << results
        f_new_selected_list << selected_list
        f_list_scores << list_scores
        f_auto_save << auto_save
      end

      f_results = f_results.flatten.uniq
      f_new_selected_list = f_new_selected_list.flatten
      f_list_scores = f_list_scores.flatten
      ret_auto_save = f_auto_save.include?("false") ? "false" : "true"
      return f_results, f_new_selected_list, f_list_scores, ret_auto_save
    else
      results, selected_list, list_scores, auto_save = Product.get_search_items_by_relavance(param, itemtypes)
      return results, selected_list, list_scores, auto_save
    end
  end

  def self.get_search_items_by_relavance(param, itemtypes=nil, for_compare="false")
    auto_save = "false"
    unless param[:category].blank?
      itemtypes = param[:category].split(',')
    end
    search_type = Product.search_type(itemtypes)
    term = param[:term]

    removed_keywords = ["review", "how", "price", "between", "comparison", "vs", "processor", "display", "battery", "features", "india", "released", "launch",
                        "release", "limited", "period", "offer", "deal", "first", "impressions", "available", "online", "android", "video", "hands on", "hands-on","access","full","depth","detailed","look","difference","update","video","top","best","list","spec","and","point","shoot","camera","mobile","tablet","car","bike"]
    term = term.gsub("-","")
    term = term.to_s.split(/\W+/).delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')
    # term = term.to_s.split.delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')
    search_type_for_data = search_type.first if search_type.is_a?(Array)
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

    ids = items.map(&:id).map(&:inspect).join(",")
    query_car_groups = "SELECT `itemrelationships`.`item_id` as item_id, items.id as car_group_id, items.name as name FROM `items` INNER JOIN `itemrelationships` ON `items`.`id` = `itemrelationships`.`relateditem_id` WHERE `items`.`type` IN ('CarGroup') AND `itemrelationships`.`item_id` IN (#{ids})"
    car_groups = ids.blank? ? [] : CarGroup.find_by_sql(query_car_groups)
    car_groups_hash = {}
    car_groups.each {|each_group| car_groups_hash.merge!("#{each_group.item_id}" => each_group.attributes.delete_if {|k,v| k == "item_id"})}

    item_names = {}
    items.each {|item| item_names.merge!("#{item.id}" => "#{item.name}")}

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
      ['App'].each do |each_new_type|
        app_items = ItemtypeTag.where("name = '#{each_new_type}'")
        app_results = Product.get_results_from_items(app_items)
        results << app_results
        results = results.flatten
      end
    end

    # if categories.include?('Games')
    #   ["Gaming Console"].each do |each_new_type|
    #     app_items = ItemtypeTag.where("name = '#{each_new_type}'")
    #     app_results = Product.get_results_from_items(app_items)
    #     results << app_results
    #     results = results.flatten
    #   end
    # end

    # items_by_score = {}
    # @items.hits.map {|dd| items_by_score.merge!("#{dd.result.id}" => dd.score) if dd.score.to_f > 0.5}
    all_items_by_score = {}
    @items.hits.map {|dd| all_items_by_score.merge!("#{dd.result.id}" => dd.score) unless dd.result.blank?}
    items_by_score = all_items_by_score.select {|key,val| val.to_f > 0.5}
    sorted_hash = Hash[items_by_score.sort_by {|k,v| -v}]
    selected_list = sorted_hash.keys.first(2)
    all_items_by_score.each {|key,val| all_items_by_score[key] = val.to_f.round(2)}
    all_items_by_score.default = 0

    if param[:ac_sub_type] == "Lists"
      selected_list = []
    elsif for_compare == "true" || param[:ac_sub_type] != "Comparisons"
      selected_list = selected_list.first(1)
    end

    groups = []
    new_selected_list = []
    list_scores = {}
    selected_items = items.select {|each_item| selected_list.include?(each_item.id.to_s)}
    selected_items.each_with_index do |each_selected_item, index|
      group = each_selected_item.cargroup rescue nil
      unless group.blank?
        groups << group
        new_selected_list << group.id.to_s
        list_scores.merge!("#{group.id}" => all_items_by_score["#{each_selected_item.id}"])
      else
        if ["Reviews", "Comparisons", "Spec"].include?(param[:ac_sub_type])
          if (each_selected_item.is_a?(Product) || each_selected_item.is_a?(CarGroup))
            new_selected_list << each_selected_item.id.to_s
            list_scores.merge!("#{each_selected_item.id}" => all_items_by_score["#{each_selected_item.id}"])
          end
        else
          new_selected_list << each_selected_item.id.to_s
          list_scores.merge!("#{each_selected_item.id}" => all_items_by_score["#{each_selected_item.id}"])
        end
      end
    end
    new_results = Product.get_results_from_items(groups)
    results << new_results
    results.flatten!
    new_selected_list.uniq!

    results.each {|each_result| each_result.merge!(:score => all_items_by_score[each_result[:id]])}
    # list_scores = sorted_hash.select {|key,_| new_selected_list.include?(key)}.values.map {|each_val| each_val.round(2)}

    items_group = {}
    items_group_names = {}
    @items.results.each do |each_item|
      cargroup = car_groups_hash["#{each_item.id}"]
      if !cargroup.blank?
        items_group.merge!("#{each_item.id}" => "#{cargroup["car_group_id"]}")
        items_group_names.merge!("#{cargroup["car_group_id"]}" => cargroup["name"])
      end
    end

    keys = all_items_by_score.keys
    values = all_items_by_score.values

    first_key = ""
    each_new_key = ""
    compare_val = 10
    keys.each_with_index do |each_key, index|
      each_new_key = each_key
        if ["Reviews", "HowTo/Guide", "News", "Photo", "Spec"].include?(param[:ac_sub_type])
          if index == 0
            first_key = each_key
            compare_val = 0.4
            next
          end
        elsif param[:ac_sub_type] == "Comparisons"
          index_val =  for_compare == "true" ? 0 : 1
          if index == index_val
            first_key = each_key
            compare_val = 0.3
            next
          end
        end
        if !items_group[first_key].blank? && !items_group[each_key].blank?
          if items_group[first_key] != items_group[each_key]
            if ((all_items_by_score[first_key].to_f - all_items_by_score[each_key].to_f) > compare_val)
              p 9999999999999999999999
              auto_save = "true"
              break
            end
          end
        else
          if ((all_items_by_score[first_key].to_f - all_items_by_score[each_key].to_f) > compare_val)
            auto_save = "true"
            break
          else
            break
          end
        end
    end

    p 1111111111
    p keys_for_title_search = all_items_by_score.select {|key,val| val >= all_items_by_score[each_new_key]}.keys
    p items_group
    p items_group_names
    p first_key
    p auto_save

    first_key_score = all_items_by_score[first_key]

    if first_key_score.to_f > 0.4 && auto_save == "false" && (for_compare == "true" || ["Reviews", "HowTo/Guide", "News", "Photo", "Spec"].include?(param[:ac_sub_type]))
      keys_for_title_search.each_with_index do |each_key, index|
        if index == 0
          first_key = each_key
          next
        end

        results_keys = results.map {|x| x[:id]}
        term = term.to_s.downcase
        if !items_group[first_key].blank? && !items_group[each_key].blank?
          if items_group[first_key] != items_group[each_key]
            p 1111111111111111111111111111111111111111
            p first_title = items_group_names[items_group[first_key]].to_s.strip
            p second_title = items_group_names[items_group[each_key]].to_s.strip
            if ((!first_title.blank? && !second_title.blank?) && (term.include?(first_title) || term.include?(second_title)))
              p 8888
              p selected_key = term.include?(first_title) == true ? first_key : each_key
              new_selected_list = [items_group[selected_key]]
              if !new_selected_list.blank? && results_keys.include?(new_selected_list.first)
                auto_save = "true"
              else
                item = items.select {|each_item| each_item.id == selected_key.to_i}.first
                item_car_group = item.cargroup rescue nil
                if !item_car_group.blank?
                  (new_groups = []) << item_car_group
                  new_results = Product.get_results_from_items(new_groups.compact)
                  if !new_results.blank?
                    auto_save = "true"
                    results << new_results
                    results.flatten!
                  end
                end
              end
              break
            end
          end
        else
          p 2222222222222222222222222222222222222222222222222222
          first_title = items_group[first_key].blank? ? item_names[first_key] : items_group_names[items_group[first_key]]
          second_title = items_group[each_key].blank? ? item_names[each_key] : items_group_names[items_group[each_key]]
          if ((!first_title.blank? && !second_title.blank?) && (term.include?(first_title.to_s.strip.downcase) || term.include?(second_title.to_s.strip.downcase)))
            p 777777
            p selected_key = term.to_s.downcase.include?(first_title.to_s.strip.downcase) == true ? first_key : each_key
            new_selected_list = items_group[selected_key].blank? ? [selected_key] : [items_group[selected_key]]
            if !new_selected_list.blank? && results_keys.include?(new_selected_list.first)
              auto_save = "true"
            else
              item = items.select {|each_item| each_item.id == selected_key.to_i}.last
              item_car_group = item.cargroup rescue nil
              if !item_car_group.blank?
                (new_groups = []) << item_car_group
                new_results = Product.get_results_from_items(new_groups.compact)
                if !new_results.blank?
                  auto_save = "true"
                  results << new_results
                  results.flatten!
                end
              end
            end
            break
          end
        end

      end
    end

    return results, new_selected_list, list_scores.values, auto_save
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
