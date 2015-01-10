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

end
