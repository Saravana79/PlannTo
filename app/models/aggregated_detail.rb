class AggregatedDetail < ActiveRecord::Base

  def self.update_aggregated_detail(time, entity_type, batch_size=1000)
    entity_field = entity_type + "_id"
    date_for_query = time.is_a?(Time) ? time.utc : time # converted to UTC

    if entity_type == "publisher"
      impression_query = "select publisher_id as entity_id,count(*) as impression_count from add_impressions where date(impression_time) = date('#{date_for_query}') group by publisher_id"
      click_query = "select publisher_id as entity_id,count(*) as click_count from clicks where date(timestamp) = date('#{date_for_query}') group by publisher_id"
    else
      impression_query = "select advertisement_id as entity_id,count(*) as impression_count from add_impressions where date(impression_time)  =  date('#{date_for_query}') and advertisement_type='advertisement' group by advertisement_id"
      click_query = "select advertisement_id as entity_id,count(*) as click_count from clicks where date(timestamp) = date('#{date_for_query}') and advertisement_id is NOT NULL group by advertisement_id"
    end

    page = 1
    begin
      impressions = AddImpression.paginate_by_sql(impression_query, :page => page, :per_page => batch_size)

      impressions.each do |each_imp|
        aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date(:entity_id => each_imp.entity_id, :date => time.to_date)
        aggregated_detail.update_attributes(:entity_type => entity_type, :impressions_count => each_imp.impression_count)
      end
      page += 1
    end while !impressions.empty?

    page = 1
    begin
      clicks = Click.paginate_by_sql(click_query, :page => page, :per_page => batch_size)

      clicks.each do |each_click|
        aggregated_detail = AggregatedDetail.find_or_initialize_by_entity_id_and_date(:entity_id => each_click.entity_id, :date => time.to_date)
        aggregated_detail.update_attributes(:entity_type => entity_type, :clicks_count => each_click.click_count)
      end
      page += 1
    end while !clicks.empty?

  end

  def self.get_counts(date1, date2, publisher_id)
    query = "SELECT sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{date1}' and '#{date2}' group by entity_id"
    results = find_by_sql(query)
    return results
  end

  def self.chart_data_widgets(publisher_id, start_date, end_date, types=[])
    if start_date.nil?
      start_date = 2.weeks.ago
    end

    if end_date.nil?
      end_date = Date.today
    end

    # range = start_date.beginning_of_day..(end_date.end_of_day + 1.day)

    # if start_date.to_date.beginning_of_month.to_s != end_date.to_date.beginning_of_month.to_s
    if (end_date.to_date - start_date.to_date).to_i > 31

      start_date = start_date.beginning_of_month
      end_date = end_date.end_of_month
      # kliks = count(
      #     :group => 'month(date)',
      #     :select => "id",
      #     # :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range, :advertisement_type => types }  # TODO: have to update based on ad type
      #     :conditions => { :entity_id => publisher_id, :entity_type => 'publisher', :date => range }
      # )

      # results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by {|each_rec| each_rec.date.month}

      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by month(date)"
      results = find_by_sql(query).group_by {|each_rec| each_rec.date.month}


      # CREATE JSON DATA FOR EACH MONTH
      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.map do |date|
        {
            impression_time: date.strftime("%b, %Y"),
            impressions: results[date.month].blank? ? 0 : results[date.month].first.impressions_count,
            clicks: results[date.month].blank? ? 0 : results[date.month].first.clicks_count
        }
      end
    else

      query = "SELECT date, sum(impressions_count) as impressions_count, sum(clicks_count) as clicks_count FROM aggregated_details WHERE entity_type='publisher' and entity_id= #{publisher_id} and date BETWEEN '#{start_date}' and '#{end_date}' group by date"

      results = find_by_sql(query).group_by {|each_rec| each_rec.date}

      # results = AggregatedDetail.where(:entity_id => publisher_id, :entity_type => 'publisher', :date => range).select("impressions_count, clicks_count, date").group_by(&:date)

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
