namespace :aggregated_detail do
  desc 'update clicks add_impressions and clicks count by item_id, publisher_id and advertisement_id'
  task :process_count => :environment do
    @add_impressions = AddImpression.all

    @add_impressions.each do |add_impression|
      date = add_impression.impression_time
      date = date.to_date if date.is_a?(Time)

      # Count AddImpressions
      # count add_impressions based on date and item_id
      ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'item', :entity_id => add_impression.item_id)
      ag_detail_by_date_item_id.impressions_count = ag_detail_by_date_item_id.impressions_count.to_i + 1
      ag_detail_by_date_item_id.save!

      # count add_impressions based on date and publisher_id
      ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'publisher', :entity_id => add_impression.publisher_id)
      ag_detail_by_date_item_id.impressions_count = ag_detail_by_date_item_id.impressions_count.to_i + 1
      ag_detail_by_date_item_id.save!

      if add_impression.advertisement_type == "advertisement" && !add_impression.advertisement_id.blank?
        # count add_impressions based on date and advertisement_id
        ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'advertisement', :entity_id => add_impression.advertisement_id)
        ag_detail_by_date_item_id.impressions_count = ag_detail_by_date_item_id.impressions_count.to_i + 1
        ag_detail_by_date_item_id.save!
      end
    end

    @clicks = Click.all

    @clicks.each do |click|
      date = click.timestamp
      date = date.to_date if date.is_a?(Time)

      # Count Clicks
      # count clicks based on date and item_id
      ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'item', :entity_id => click.item_id)
      ag_detail_by_date_item_id.clicks_count = ag_detail_by_date_item_id.clicks_count.to_i + 1
      ag_detail_by_date_item_id.save!

      # count clicks based on date and publisher_id
      ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'publisher', :entity_id => click.publisher_id)
      ag_detail_by_date_item_id.clicks_count = ag_detail_by_date_item_id.clicks_count.to_i + 1
      ag_detail_by_date_item_id.save!

      #if add_impression.advertisement_type == "advertisement" && !add_impression.advertisement_id.blank?
      #  # count clicks based on date and advertisement_id
      #  ag_detail_by_date_item_id = AggregatedDetail.find_or_create_by_date_and_entity_type_and_entity_id(:date => date, :entity_type => 'advertisement', :entity_id => click.advertisement_id)
      #  ag_detail_by_date_item_id.clicks_count = ag_detail_by_date_item_id.clicks_count.to_i + 1
      #  ag_detail_by_date_item_id.save!
      #end
    end

    puts "**************************************************************************************"
    puts "Successfully updated aggregated details"
    puts "**************************************************************************************"
  end

end