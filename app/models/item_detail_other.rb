class ItemDetailOther < ActiveRecord::Base

  has_many :item_detail_other_mappings


  def self.update_item_detail_other_for_junglee(url)
    # url ||= "http://www.junglee.com/dp/B00RGA4F3U"
    url = url.to_s
    url = "http://" + url if !url.include?("http")

    doc = Nokogiri::XML(open(url))
    node = doc.elements.first

    table = node.at_css(".centerColumn #center-5 table")
    title = node.at_css(".productTitle").content.squish rescue ""
    price = node.at_css(".whole-price").content.squish rescue ""
    price = price.gsub(",","").gsub(".", "")
    location = node.at_css("#location .importantDetail").content.squish rescue ""
    status = 1
    search_text = ""
    ad_detail1 = ""
    ad_detail2 = ""
    ad_detail3 = ""
    ad_detail4 = ""
    table.elements.each do |each_ele|
      type = each_ele.elements.first.content.to_s.squish rescue ""
      value = each_ele.elements.last.content.to_s.squish rescue ""
      if type == "Brand"
        search_text = value
      elsif type == "Model"
        search_text = search_text + " " + value
      elsif type == "Version"
        search_text = search_text + " " + value
      elsif type == "Year of Registration"
        ad_detail4 = value
      elsif type == "KMs Driven"
        ad_detail2 = value
      elsif type == "Fuel Type"
        ad_detail1 = value
      elsif type == "Transmission Type"
        ad_detail3 = value
      end
    end

    item_detail_other = ItemDetailOther.where(:url => url).last

    if item_detail_other.blank?
      item_detail_other = ItemDetailOther.new(:title => title, :price => price, :url => url, :status => status, :ad_detail1 => ad_detail1, :ad_detail2 => ad_detail2,
                                              :ad_detail3 => ad_detail3, :ad_detail4 => ad_detail4, :added_date => Date.today, :last_modified_date => Date.today)
      item_detail_other.save!

      @items = Sunspot.search([City]) do
        keywords location do
          minimum_match 1
        end
        order_by :score,:desc
        order_by :orderbyid , :asc
        paginate(:page => 1, :per_page => 5)
      end

      item = @items.results.first rescue nil

      if !item.blank?
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => item.id)
      end

      cars = Sunspot.search([Car]) do
        keywords search_text do
          minimum_match 1
        end
        order_by :score,:desc
        order_by :orderbyid , :asc
        paginate(:page => 1, :per_page => 5)
      end

      car = cars.results.first rescue nil

      if !car.blank?
        ItemDetailOtherMapping.create(:item_detail_other_id => item_detail_other.id, :item_id => car.id)
      end

    else
      item_detail_other.update_attributes(:price => price, :last_modified_date => Date.today)
    end
  end

end
