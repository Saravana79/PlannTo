clock: bundle exec clockwork lib/clock.rb
worker: INTERVAL=0.1 QUEUES=update_redis,item_update_process,buying_list_process,rtb_budget_update_for_ad_1,rtb_budget_update_process,bulk_create_impression_and_click,bulk_cookie_matching_process,aggregated_detail_process,ad_statistic_process,article_content_process,popular_vendor_products_update,advertisement_process,content_ad_detail_process,sid_ad_detail_process,update_content_relations,feed_process,automated_feed_process,item_ad_detail_process,missing_record_process,related_item_update_process,source_item_process,add_voting_points,generate_report_process,clean_up_redis_keys,process_source_categories,update_item_details_from_vendors,update_item_details_from_vendors_flipkart,ad_hourly_spent_detail_process,article_content_process_auto exec bundle exec rake jobs:work