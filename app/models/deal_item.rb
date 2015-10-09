class DealItem < ActiveRecord::Base

  def self.get_deal_item_based_on_hour(random_id, for_widget="false")
    filter_condition = ""
    if for_widget == "true"
      filter_arr = [976419031,1805560031,1375424031,1388977031,1350380031,1983518031,4091095031,1983396031,1350387031,1389396031,1380369031,1389375031,1355016031,1378509031,1983550031,10272111]
      filter_condition = " and category in (#{filter_arr.map(&:inspect).join(",")})"
    end
    items = DealItem.where("start_time < '#{Time.now.utc}' and end_time > '#{Time.now.utc}' #{filter_condition}").order("rand()").limit(6)

    # order_by_condition = " order by rand() limit 12"
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
        each_row = CSV.parse_line(each_row)
        if indx == 0
          headers = each_row
          next
        end

        url = each_row[11].to_s
        deal_item = DealItem.where(:url => url).last

        if !deal_item.blank?
          deal_item.update_attributes(:deal_id => each_row[0].to_s, :deal_type => each_row[1].to_s, :deal_state => each_row[2].to_s, :category => each_row[3].to_s, :asin => each_row[4].to_s, :deal_title => each_row[5].to_s, :start_time => each_row[6].to_s, :end_time => each_row[7].to_s, :list_price => each_row[8].to_s, :deal_price => each_row[9].to_s, :discount => ((each_row[10].to_s.blank? || each_row[10].to_s == "NA") ? nil : each_row[10].to_s), :image_url => each_row[12].to_s, :browse_node_id1 => each_row[13].to_s, :sub_category_path1 => each_row[14].to_s, :browse_node_id2 => each_row[15].to_s, :sub_category_path2 => each_row[16].to_s, :last_updated_at => Time.now)
        else
          deal_items << DealItem.new(:deal_id => each_row[0].to_s, :deal_type => each_row[1].to_s, :deal_state => each_row[2].to_s, :category => each_row[3].to_s, :asin => each_row[4].to_s, :deal_title => each_row[5].to_s, :start_time => each_row[6].to_s, :end_time => each_row[7].to_s, :list_price => each_row[8].to_s, :deal_price => each_row[9].to_s, :discount => ((each_row[10].to_s.blank? || each_row[10].to_s == "NA") ? nil : each_row[10].to_s), :url => each_row[11].to_s, :image_url => each_row[12].to_s, :browse_node_id1 => each_row[13].to_s, :sub_category_path1 => each_row[14].to_s, :browse_node_id2 => each_row[15].to_s, :sub_category_path2 => each_row[16].to_s, :last_updated_at => Time.now)
        end
      end

      DealItem.import(deal_items)
    rescue Exception => e
      p "Error while updating daily deals"
    end
  end
end
