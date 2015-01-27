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

   if (type.blank? || type.include?("Others"))
      return [ "ItemtypeTag".camelize.constantize, "AttributeTag".camelize.constantize,"Topic".camelize.constantize,"Manufacturer".camelize.constantize, "CarGroup".camelize.constantize,"Mobile".camelize.constantize, "Tablet".camelize.constantize, "Car".camelize.constantize, "Camera".camelize.constantize,"Game".camelize.constantize,"Console".camelize.constantize,"WearableGadget".camelize.constantize,"Laptop".camelize.constantize,"Bike".camelize.constantize,"Cycle".camelize.constantize,"Tablet".camelize.constantize,"Hotel".camelize.constantize,"City".camelize.constantize,"Lens".camelize.constantize,"Television".camelize.constantize, "Beauty".camelize.constantize,"Color".camelize.constantize,"ApartmentType".camelize.constantize,"ApartmentSaleType".camelize.constantize,"Place".camelize.constantize,"State".camelize.constantize,"City".camelize.constantize]
   end
   if type.is_a?(Array)
     return_val = type.collect{|t| t.to_s.gsub(/\s+/,'').strip.camelize.singularize.constantize rescue t.to_s.gsub(/\s+/,'').strip.camelize.constantize}
   else
      return_val = [*type.to_s.gsub(/\s+/,'').strip.camelize.singularize.constantize] rescue [*type.to_s.gsub(/\s+/,'').strip.camelize.constantize]
   end

    
   if !type.blank?
    return_val = return_val + ["WearableGadget".camelize.constantize] if type.include?("Mobile")
    return_val = return_val + ["Console".camelize.constantize] if type.include?("Games")
    return_val = return_val + ["Lens".camelize.constantize] if type.include?("Camera")
   end

   return return_val
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

  def self.call_search_items_by_relavance_housing(param, itemtypes=nil)
    final_results = []
    selected_list = []
    list_scores = []
    term = param[:term].to_s

    spl_term = term.split(";")

    ap_type = spl_term[0].to_s.split("-")[1].to_s.strip

    ap_sale_type = spl_term[1].to_s.split("-")[1].to_s.strip

    location = spl_term[2].to_s.split("-")[1].to_s.strip

    apartment_types = ApartmentType.where(:name => ["Land", "Apartment"])

    apartment_types.each do |each_apartment_type|
      final_results << {:id => each_apartment_type.id, :value => each_apartment_type.name, :imgsrc =>"", :type => "ApartmentType", :url => "" }
    end

    apartment_type_name = ""

    if !ap_type.blank?
      if ap_type.to_s.downcase.match(/land/)
        apartment_type_name = "Land"
      elsif ap_type.to_s.downcase.match(/apartment/) || ap_type.to_s.downcase.match(/plot/)
        apartment_type_name = "Apartment"
      elsif ap_type.to_s.downcase.match(/individual house/) || ap_type.to_s.downcase.match(/house/)
        apartment_type_name = "Individual House"
      end

      if !apartment_type_name.blank?
        names = final_results.map {|result| result[:value]}

        if !names.include?(apartment_type_name)
          apartment_type = ApartmentType.where(:name => apartment_type_name).first
          if !apartment_type.blank?
            final_results << {:id => apartment_type.id, :value => apartment_type.name, :imgsrc =>"", :type => "ApartmentType", :url => "" }
            selected_list << apartment_type.id
          end
        end
      end
    end

    apartment_sale_types = ApartmentSaleType.where(:name => "For Sale")

    apartment_sale_types.each do |each_apartment_sale_type|
      final_results << {:id => each_apartment_sale_type.id, :value => each_apartment_sale_type.name, :imgsrc =>"", :type => "ApartmentSaleType", :url => "" }
    end

    apartment_sale_type_name = ""
    if !ap_sale_type.blank?
      if ap_sale_type.to_s.downcase.match(/sale/)
        apartment_sale_type_name = "For Sale"
      elsif ap_sale_type.to_s.downcase.match(/rent/)
        apartment_sale_type_name = "For Rent"
      elsif ap_sale_type.to_s.downcase.match(/lease/)
        apartment_sale_type_name = "For Lease"
      end

      if !apartment_sale_type_name.blank?
        names = final_results.map {|result| result[:value]}

        if !names.include?(apartment_sale_type_name)
          apartment_sale_type = ApartmentSaleType.where(:name => apartment_sale_type_name).first
          if !apartment_sale_type.blank?
            final_results << {:id => apartment_sale_type.id, :value => apartment_sale_type.name, :imgsrc =>"", :type => "ApartmentSaleType", :url => "" }
            selected_list << apartment_sale_type.id
          end
        end
      end
    end

    location = location.gsub("-"," ").gsub("_", " ")

    removed_keywords = ["review", "how", "price", "between", "comparison", "vs", "processor", "display", "battery", "features", "india", "released", "launch",
                        "release", "limited", "period", "offer", "deal", "first", "impressions", "available", "online", "android", "video", "hands on", "hands-on",
                        "access","full","depth","detailed","look","difference","update","video","top","best","list","spec","and","point","shoot","camera","mobile",
                        "tablet","car","bike", "tips", "beauty", "makeup", "blog", "look", "product", "brown girls", "swatches", "swatch"]
    location = location.to_s.split(/\W+/).delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')

    @items = Sunspot.search([Place]) do
      keywords location do
        minimum_match 1
      end
      order_by :score,:desc
      order_by :orderbyid , :asc
      paginate(:page => 1, :per_page => 5)
    end

    items = @items.results
    results = []

    items.each do |item|
      url = item.get_url()
      image_url = item.image_url(:small)
      name = item.name.to_s
      city_name = "(#{item.related_city.name.to_s})" rescue ""
      f_name = "#{name} #{city_name}"
      results << {:id => item.id.to_s, :value => f_name, :imgsrc =>image_url, :type => "Place", :url => url }
    end

    final_results << results

    final_results = final_results.flatten
    selected_list << results.first[:id] if !results.first.blank?

    auto_save = false

    return final_results, selected_list, list_scores, auto_save
  end

  def self.get_search_items_by_relavance(param, itemtypes=nil, for_compare="false")
    auto_save = "false"
    unless param[:category].blank?
      itemtypes = param[:category].split(',')
      if itemtypes.include?("Beauty")
        itemtypes << ["Color", "Manufacturer"]
        itemtypes = itemtypes.flatten
      end
    end
    search_type = Product.search_type(itemtypes)
    term = param[:term]

    removed_keywords = ["review", "how", "price", "between", "comparison", "vs", "processor", "display", "battery", "features", "india", "released", "launch",
                        "release", "limited", "period", "offer", "deal", "first", "impressions", "available", "online", "android", "video", "hands on", "hands-on",
                        "access","full","depth","detailed","look","difference","update","video","top","best","list","spec","and","point","shoot","camera","mobile",
                        "tablet","car","bike", "tips", "beauty", "makeup", "blog", "look", "product", "brown girls", "swatches", "swatch"]
    term = term.gsub("-","")
    term = term.to_s.split(/\W+/).delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')
    # term = term.to_s.split.delete_if{|x| removed_keywords.include?(x.downcase)}.join(' ')
    search_type_for_data = search_type.first if search_type.is_a?(Array)
    @items = Sunspot.search(search_type) do
      keywords term do
        minimum_match 1
      end
      with :status, [1,2,3]
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
    item_names.each {|k,v| splt_val = v.split(" "); if splt_val.count > 2; splt_val.shift; item_names[k]=splt_val.join(" ");end}
    item_names.each {|k,v| item_names[k] = v.to_s.split(/\W+/).join(' ')}

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
      ['App', 'WearableGadget'].each do |each_new_type|
        app_items = ItemtypeTag.where("name = '#{each_new_type}'")
        app_results = Product.get_results_from_items(app_items)
        results << app_results
        results = results.flatten
      end
    end

    if categories.include?('Games')
      ["Console"].each do |each_new_type|
        app_items = ItemtypeTag.where("name = '#{each_new_type}'")
        app_results = Product.get_results_from_items(app_items)
        results << app_results
        results = results.flatten
      end
    end

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
        search_type_arr = search_type.is_a?(Array) ? search_type : [search_type].compact
        if (["Reviews", "Comparisons", "Spec"].include?(param[:ac_sub_type]) && search_type.include?(Beauty))
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

    items_group_names.each {|k,v| splt_val = v.split(" "); if splt_val.count > 2; splt_val.shift; items_group_names[k]=splt_val.join(" ");end}
    items_group_names.each {|k,v| items_group_names[k] = v.to_s.split(/\W+/).join(' ')}

    keys = all_items_by_score.keys
    values = all_items_by_score.values

    first_key = ""
    each_new_key = ""
    compare_val = 10
    keys.each_with_index do |each_key, index|
      each_new_key = each_key
        if ["Reviews", "HowTo/Guide", "News", "Photo", "Spec", "Resale"].include?(param[:ac_sub_type])
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

    keys_for_title_search = all_items_by_score.select {|key,val| val >= all_items_by_score[each_new_key]}.keys

    # first_key = keys_for_title_search.first if first_key.blank?

    first_key_score = all_items_by_score[first_key]

    # if param[:ac_sub_type] == "Others" && keys_for_title_search.count == 1 && term.to_s.strip == item_names[first_key]
    #   auto_save = "true"
    # end

    if first_key_score.to_f > 0.4 && auto_save == "false" && (for_compare == "true" || ["Reviews", "HowTo/Guide", "News", "Photo", "Spec", "Resale"].include?(param[:ac_sub_type]))

      keys_for_title_search.each_with_index do |each_key, index|
        if index == 0
          first_key = each_key
          next
        end

        results_keys = results.map {|x| x[:id]}
        term = term.to_s.downcase
        if !items_group[first_key].blank? && !items_group[each_key].blank?
          each_key_pos = keys_for_title_search.index(each_key) + 1
          check_res = keys_for_title_search.count <= each_key_pos
          if ((items_group[first_key] != items_group[each_key]) || check_res)
            first_title = items_group_names[items_group[first_key]].to_s.strip.downcase
            second_title = items_group_names[items_group[each_key]].to_s.strip.downcase
            if ((!first_title.blank? && !second_title.blank?) && (term.include?(first_title) || term.include?(second_title)))
              selected_key = term.include?(first_title) == true ? first_key : each_key
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
          first_title = items_group[first_key].blank? ? item_names[first_key] : items_group_names[items_group[first_key]]
          second_title = items_group[each_key].blank? ? item_names[each_key] : items_group_names[items_group[each_key]]
          if ((!first_title.blank? && !second_title.blank?) && (term.include?(first_title.to_s.strip.downcase) || term.include?(second_title.to_s.strip.downcase)))
            selected_key = term.to_s.downcase.include?(first_title.to_s.strip.downcase) == true ? first_key : each_key
            new_selected_list = items_group[selected_key].blank? ? [selected_key] : [items_group[selected_key]]
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

      end
    end
    new_selected_list = new_selected_list.uniq

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
        type = item.type.to_s.humanize
      end

      # end
      url = item.get_url()
      # image_url = item.image_url
      {:id => item.id.to_s, :value => item.get_name, :imgsrc =>image_url, :type => type, :url => url }
    }

    return results
  end

end
