class AggregatedDetail < ActiveRecord::Base
  def self.chart_data_widgets(publisher_id, start_date, end_date, types=[])
    if start_date.nil?
      start_date = 2.weeks.ago
    end

    if end_date.nil?
      end_date = Date.today
    end

    range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

    if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s

      # kliks = count(
      #     :group => 'month(date)',
      #     :select => "id",
      #     # :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range, :advertisement_type => types }  # TODO: have to update based on ad type
      #     :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range }
      # )

      results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by {|each_rec| each_rec.date.month}

      # CREATE JSON DATA FOR EACH MONTH
      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
        {
            impression_time: date.strftime("%b, %Y"),
            impressions: results[date.month].blank? ? 0 : results[date.month].first.impressions_count,
            clicks: results[date.month].blank? ? 0 : results[date.month].first.clicks_count
        }
      end


    else

      results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by(&:date)

      #WORKS FINE DATA FOR EACH DAY
      (start_date.to_date..end_date.to_date).map do |date|
        {
            impression_time: date.strftime("%F"),
            impressions: results[date].blank? ? 0 : results[date].first.impressions_count,
            clicks: results[date].blank? ? 0 : results[date].first.clicks_count
        }
      end
    end
  end

  # def self.chart_data_widgets_for_click(publisher_id, start_date, end_date, types, vendor_id)
  #   if start_date.nil?
  #     start_date = 2.weeks.ago
  #   end
  #
  #   if end_date.nil?
  #     end_date = Date.today
  #   end
  #
  #   range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)
  #
  #   # conditions = { :add_impressions => {:advertisement_type => [types]}, :publisher_id => publisher_id , :timestamp => range, :vendor_id => vendor_id }
  #   conditions = { :entity_id => publisher_id, :entity_type => 'publisher', :date => range }
  #
  #   # conditions.delete(:vendor_id) if vendor_id.blank?
  #
  #   if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
  #
  #     kliks = count(
  #
  #         # :joins => [:add_impression],
  #         :group => 'month(date)',
  #         :conditions => conditions
  #     )
  #
  #     # CREATE JSON DATA FOR EACH MONTH
  #     (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
  #       {
  #           impression_time: date.strftime("%b, %Y"),
  #           clicks: kliks[date.month] || 0
  #       }
  #     end
  #
  #
  #   else
  #
  #     kliks = count(
  #         # :joins => [:add_impression],
  #         :group => 'date(date)',
  #         :conditions => conditions
  #     )
  #
  #     #WORKS FINE DATA FOR EACH DAY
  #     (start_date.to_date..end_date.to_date).map do |date|
  #       {
  #           impression_time: date.strftime("%F"),
  #           clicks: kliks[date] || 0
  #       }
  #     end
  #   end
  # end

end
