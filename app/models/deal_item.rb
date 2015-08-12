class DealItem < ActiveRecord::Base


  def self.get_deal_item_based_on_hour(random_id)
    # order_by_condition = " order by rand() limit 12"
    items = DealItem.where("start_time < '#{Time.now.utc}' and end_time > '#{Time.now.utc}'").order("rand()").limit(6)
    # p items = DealItem.where("id=1085").order("rand()").limit(6)
  end
end
