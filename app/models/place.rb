class Place < Item
  has_one :itemrelationship, :foreign_key => :item_id
  has_one :related_city, :through => :itemrelationship

  # has_many :hotel_vendor_details, :foreign_key => :item_id

  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 2.0,  :as => :name_ac do |item|
      tempName = item.name.gsub("-","")
      if (!item.related_city.blank?)
        tempName = tempName + " " + item.related_city.to_s.gsub("-", "")
      end
      tempName
    end

    text :nameformlt do |item|
      item.name.to_s.gsub("-", "")
    end

    string :status

    time :created_at

    float :rating  do |item|
      item.rating
    end
    integer :orderbyid  do |item|
      item.itemtype.orderby
    end
    dynamic_float :features do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        if attribute_value.attribute.search_display_attributes.nil?
          hash
        else
          if attribute_value.attribute.attribute_type == "Numeric"
            hash.merge(attribute_value.attribute.name.parameterize.underscore.to_sym => attribute_value.value)
          else
            hash
          end
        end
      end
    end

    dynamic_string :features_string do |car|
      car.attribute_values.inject({}) do |hash,attribute_value|
        if attribute_value.attribute.search_display_attributes.nil?
          hash
        else
          if attribute_value.attribute.attribute_type != "Numeric"
            hash.merge(attribute_value.attribute.name.parameterize.underscore.to_sym => attribute_value.value)
          else
            hash
          end

        end
      end
    end

    location(:location) do |place|

      latitude = place.latitude
      longitude = place.longitude
      if !latitude.blank? && !longitude.blank?
        Sunspot::Util::Coordinates.new(latitude, longitude)
      end
    end

  end

  def latitude
    lat = self.attribute_values.where(:attribute_id => 415).last
    if lat.blank?
      nil
    else
      lat.value.to_d
    end
  end

  def longitude
    lat = self.attribute_values.where(:attribute_id => 416).last
    if lat.blank?
      nil
    else
      lat.value.to_d
    end
  end


  def self.city_state_place_process
    base_path = "http://cdn1.plannto.com/static/housing"

    # Country, State and place
    ["Country", "State", "City", "Place"].each do |type|
      itemtype = Itemtype.find_or_initialize_by_itemtype(type)
      itemtype.description = "Contains list of '#{type.downcase}'"
      itemtype.orderby = 18
      itemtype.save!
    end

    country_itemtype = Itemtype.find_by_itemtype("Country")
    state_itemtype = Itemtype.find_by_itemtype("State")
    city_itemtype = Itemtype.find_by_itemtype("City")
    place_itemtype = Itemtype.find_by_itemtype("Place")

    #create attributes
    latitude = Attribute.find_or_initialize_by_name(:name => "Latitude", :attribute_type => "String", :category_name => "Location")
    latitude.save!
    longitude = Attribute.find_or_initialize_by_name(:name => "Longitude", :attribute_type => "String", :category_name => "Location")
    longitude.save!
    place_series = Attribute.find_or_initialize_by_name(:name => "PlaceSeries", :attribute_type => "String", :category_name => "Location")
    place_series.save!
    place_code = Attribute.find_or_initialize_by_name(:name => "PlaceCode", :attribute_type => "String", :category_name => "Location")
    place_code.save!
    reference = Attribute.find_or_initialize_by_name(:name => "Reference ID", :attribute_type => "String", :category_name => "General")
    reference.save!
    code = Attribute.find_or_initialize_by_name(:name => "Code", :attribute_type => "String", :category_name => "Location")
    code.save!

    #create country
    country = Country.find_or_initialize_by_name("India")
    country.itemtype_id = country_itemtype.id
    country.save!(:validate => false)

    #create state

    # state_details = CSV.read("#{base_path}/admin1CodesASCII.txt")
    #
    # state_details.each do |state_detail|
    #   next if !state_detail[0].include?("IN.")
    #   p state_detail
    #   state_reference_id = state_detail[3]
    #   state_name =  state_detail[2]
    #   code_val = state_detail[0].gsub("IN.", "")
    #   state = State.find_or_initialize_by_name(state_name)
    #   state.itemtype_id = state_itemtype.id
    #   if state.save(:validate => false)
    #     #create or update reference_id
    #     ref = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(reference.id, state.id)
    #     ref.update_attributes(:value => state_reference_id)
    #
    #     #create or update code
    #     state_code = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(code.id, state.id)
    #     state_code.update_attributes(:value => code_val)
    #
    #     #create relationship with country
    #     relation = Itemrelationship.find_or_initialize_by_item_id_and_relationtype(state.id, "State")
    #     relation.update_attributes(:relateditem_id => country.id)
    #   end
    # end
    #
    # # Match states and codes
    # query = "select i.id as item_id, av.value as code from items i inner join attribute_values av on av.item_id = i.id where itemtype_id = #{state_itemtype.id} and av.attribute_id = #{code.id}"
    # state_items = Item.find_by_sql(query)
    #
    # match_state_code = {}
    # state_items.each {|each_state| match_state_code.merge!("#{each_state.code}" => "#{each_state.item_id}")}
    #
    # #create city
    # city_details = CSV.read("#{base_path}/admin2Codes.txt", { :col_sep => "\t" })
    #
    # city_details.each do |city_detail|
    #   if city_detail[0].include?("IN.") && !city_detail[0].include?(".IN.")
    #     p city_detail
    #     city_reference_id = city_detail[3]
    #     city_name =  city_detail[2]
    #     city = City.find_or_initialize_by_name(city_name)
    #     city.itemtype_id = city_itemtype.id
    #     state_code_val = city_detail[0].split(".")[1]
    #     city_code_val = city_detail[0].split(".")[2]
    #
    #     if city.save(:validate => false)
    #       # create or update reference_id
    #       ref = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(reference.id, city.id)
    #       ref.update_attributes(:value => city_reference_id)
    #
    #       # create or update city_code
    #       ref = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(code.id, city.id)
    #       ref.update_attributes(:value => city_code_val)
    #
    #       #create relationship with states
    #       relateditem_id = match_state_code[state_code_val]
    #       relation = Itemrelationship.find_or_initialize_by_item_id_and_relationtype(city.id, "City")
    #       relation.update_attributes(:relateditem_id => relateditem_id)
    #     end
    #   end
    # end


    #city items
    query = "select i.id as item_id, av.value as code from items i inner join attribute_values av on av.item_id = i.id where itemtype_id = #{city_itemtype.id} and av.attribute_id = #{code.id}"
    city_items = Item.find_by_sql(query)

    error_rows = []

    match_city_code = {}
    city_items.each {|each_city| match_city_code.merge!("#{each_city.code}" => "#{each_city.item_id}")}

    #create places
    # place_details = CSV.read("#{base_path}/IN/IN.txt", { :col_sep => "\t" })
    url = "#{base_path}/IN/IN_new_1.txt"
    place_details = Place.read_csv_from_aws(url)

    place_details = place_details.uniq {|detail| "#{detail[2]}-#{detail[10]}-#{detail[11]}"}

    place_details.each do |place_detail|
      if !place_detail[10].blank? && !place_detail[11].blank?
        p place_detail
        # logger.info place_detail
        place_reference_id = place_detail[0]
        place_name =  place_detail[2]

        existing_item = Item.where(:name => place_name).last

        if !existing_item.blank? && [State,City].include?(existing_item.class)

          # check and update state and city
          latitude_val = place_detail[4]
          longitude_val = place_detail[5]

          place_series_val = place_detail[6]
          place_code_val = place_detail[7]

          # create or update latitude
          if !latitude_val.blank?
            s_c_lat = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(latitude.id, existing_item.id)
            s_c_lat.update_attributes(:value => latitude_val)
          end

          # create or update longitude
          if !longitude_val.blank?
            s_c_lat = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(longitude.id, existing_item.id)
            s_c_lat.update_attributes(:value => longitude_val)
          end

          # create or update place code series
          if !place_series_val.blank?
            s_c_place_series = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(place_series.id, existing_item.id)
            s_c_place_series.update_attributes(:value => place_series_val)
          end

          # create or update place code
          if !place_code_val.blank?
            s_c_place_code = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(place_code.id, existing_item.id)
            s_c_place_code.update_attributes(:value => place_code_val)
          end

          next
        end

        place = Place.find_or_initialize_by_name(place_name) #TODO: Create duplicate if city is different

        next if !place.new_record?

        # place = Place.new(:name => place_name)
        place.itemtype_id = place_itemtype.id
        state_code_val = place_detail[10]
        city_code_val = place_detail[11]

        city_code_val	= city_code_val.to_s.rjust(3, "0") if city_code_val.length < 3

        latitude_val = place_detail[4]
        longitude_val = place_detail[5]
        place_series_val = place_detail[6]
        place_code_val = place_detail[7]

        if place.save(:validate => false)
          # create or update reference_id
          if !place_reference_id.blank?
            ref = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(reference.id, place.id)
            ref.update_attributes(:value => place_reference_id)
          end

          # create or update latitude
          if !latitude_val.blank?
            lat = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(latitude.id, place.id)
            lat.update_attributes(:value => latitude_val)
          end

          # create or update longitude
          if !longitude_val.blank?
            lat = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(longitude.id, place.id)
            lat.update_attributes(:value => longitude_val)
          end

          # create or update place code series
          if !place_series_val.blank?
            s_c_place_series = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(place_series.id, place.id)
            s_c_place_series.update_attributes(:value => place_series_val)
          end

          # create or update place code
          if !place_code_val.blank?
            s_c_place_code = AttributeValue.find_or_initialize_by_attribute_id_and_item_id(place_code.id, place.id)
            s_c_place_code.update_attributes(:value => place_code_val)
          end

          #create relationship with city
          begin
            relateditem_id = match_city_code[city_code_val]
            relation = Itemrelationship.find_or_initialize_by_item_id_and_relationtype(place.id, "Place")
            relation.update_attributes(:relateditem_id => relateditem_id)
          rescue Exception => e
            p "Error while processing"
            p place_detail
            error_rows << place_detail
          end

        end
      end
    end
  end

  def self.read_csv_from_aws(url)
    p url
    csv_details = []
    CSV.new(open(url), :col_sep => "\t").each do |line|
      csv_details << line
    end
    csv_details
  end


end
