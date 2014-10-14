class SourceCategory < ActiveRecord::Base
  validates_uniqueness_of :source
  after_save :check_and_assign_sources_hash_to_cache_from_table

  def self.update_all_to_cache()
    results = {}
    source_categories = SourceCategory.all

    results = {}
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| results.merge!({each_src["source"] => {"categories" => each_src["categories"], "check_details" => each_src["check_details"], "site_status" => each_src["site_status"]}})}
    $redis_rtb.set("sources_list_details", title_results.to_json)
  end

  def check_and_assign_sources_hash_to_cache_from_table()
    begin
      sources_list = JSON.parse($redis_rtb.get("sources_list_details"))
    rescue Exception => e
      sources_list = {}
    end
    sources_list.merge!({self.source => {"categories" => self.categories, "check_details" => self.check_details, "site_status" => self.site_status}})
    $redis_rtb.set("sources_list_details", sources_list.to_json)
  end

  def self.get_source_category_with_paginations()
    source_categories = {}
    SourceCategory.all.map {|f| source_categories.merge!({f.source => {"pattern" => f.pattern}})}
    source_categories
  end
end
