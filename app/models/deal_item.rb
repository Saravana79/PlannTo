class DealItem < ActiveRecord::Base

  def self.get_deal_item_based_on_hour(random_id)
    # order_by_condition = " order by rand() limit 12"
    items = DealItem.where("start_time < '#{Time.now.utc}' and end_time > '#{Time.now.utc}'").order("rand()").limit(6)
    # p items = DealItem.where("id=1085").order("rand()").limit(6)
  end

  def site
    "9882"
  end

  def self.update_amazon_deals()
    begin
      url = "https://assoc-datafeeds-eu.amazon.com/datafeed/getFeed?filename=in_amazon_df_deals.csv.gz"
      xml_response = OrderHistory.get_order_details_from_amazon(url, "pla04", "cyn04")
      deal_items = []

      xml_response.split("\n").each_with_index do |each_row, indx|
        each_row = each_row.split(",")
        if indx == 0
          headers = each_row
          next
        end

        url = each_row[11].to_s.gsub(/["\\]/,'')
        deal_item = DealItem.where(:url => url).last

        if !deal_item.blank?
          deal_item.update_attributes(:deal_id => each_row[0].to_s.gsub(/["\\]/,''), :deal_type => each_row[1].to_s.gsub(/["\\]/,''), :deal_state => each_row[2].to_s.gsub(/["\\]/,''), :category => each_row[3].to_s.gsub(/["\\]/,''), :asin => each_row[4].to_s.gsub(/["\\]/,''), :deal_title => each_row[5].to_s.gsub(/["\\]/,''), :start_time => each_row[6].to_s.gsub(/["\\]/,''), :end_time => each_row[7].to_s.gsub(/["\\]/,''), :list_price => each_row[8].to_s.gsub(/["\\]/,''), :deal_price => each_row[9].to_s.gsub(/["\\]/,''), :discount => ((each_row[10].to_s.gsub(/["\\]/,'').blank? || each_row[10].to_s.gsub(/["\\]/,'') == "NA") ? nil : each_row[10].to_s.gsub(/["\\]/,'')), :image_url => each_row[12].to_s.gsub(/["\\]/,''), :browse_node_id1 => each_row[13].to_s.gsub(/["\\]/,''), :sub_category_path1 => each_row[14].to_s.gsub(/["\\]/,''), :browse_node_id2 => each_row[15].to_s.gsub(/["\\]/,''), :sub_category_path2 => each_row[16].to_s.gsub(/["\\]/,''), :last_updated_at => Time.now)
        else
          deal_items << DealItem.new(:deal_id => each_row[0].to_s.gsub(/["\\]/,''), :deal_type => each_row[1].to_s.gsub(/["\\]/,''), :deal_state => each_row[2].to_s.gsub(/["\\]/,''), :category => each_row[3].to_s.gsub(/["\\]/,''), :asin => each_row[4].to_s.gsub(/["\\]/,''), :deal_title => each_row[5].to_s.gsub(/["\\]/,''), :start_time => each_row[6].to_s.gsub(/["\\]/,''), :end_time => each_row[7].to_s.gsub(/["\\]/,''), :list_price => each_row[8].to_s.gsub(/["\\]/,''), :deal_price => each_row[9].to_s.gsub(/["\\]/,''), :discount => ((each_row[10].to_s.gsub(/["\\]/,'').blank? || each_row[10].to_s.gsub(/["\\]/,'') == "NA") ? nil : each_row[10].to_s.gsub(/["\\]/,'')), :url => each_row[11].to_s.gsub(/["\\]/,''), :image_url => each_row[12].to_s.gsub(/["\\]/,''), :browse_node_id1 => each_row[13].to_s.gsub(/["\\]/,''), :sub_category_path1 => each_row[14].to_s.gsub(/["\\]/,''), :browse_node_id2 => each_row[15].to_s.gsub(/["\\]/,''), :sub_category_path2 => each_row[16].to_s.gsub(/["\\]/,''), :last_updated_at => Time.now)
        end
      end

      DealItem.import(deal_items)
    rescue Exception => e
      p "Error while updating daily deals"
    end
  end
end
