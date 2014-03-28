class Sourceitem < ActiveRecord::Base

  def self.update_suggestions
    @source_items = Sourceitem.where(:verified => false, :suggestion_id => nil)
    count = 0
    @source_items.each do |source_item|
      begin
        param = {:term => source_item.name}
        result = Product.get_search_items_by_relavance(param).first
        unless result.blank?
          count = count + 1
          source_item.update_attributes!(:suggestion_id => result[:id], :suggestion_name => result[:value])
        end
      rescue Exception => e
        puts e.backtrace
      end
    end
    count
  end
end
