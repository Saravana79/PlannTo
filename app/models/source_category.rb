class SourceCategory < ActiveRecord::Base
  validates_uniqueness_of :source
  after_save :check_and_assign_sources_hash_to_cache_from_table

  def self.update_all_to_cache()
    results = {}
    source_categories = SourceCategory.all
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| results.merge!({each_src["source"] => each_src["categories"]})}
    results.default = "Others"
    $redis_rtb.set("feed_url-sources-list", results.to_json)

    #update for title check
    title_results = {}
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| title_results.merge!({each_src["source"] => {"check_details" => each_src["check_details"]}})}
    $redis_rtb.set("sources_list_title_results", title_results.to_json)
  end

  def check_and_assign_sources_hash_to_cache_from_table()
    begin
      sources_list = JSON.parse($redis_rtb.get("feed_url-sources-list"))
      sources_list.default = "Others"
    rescue Exception => e
      sources_list = {}
    end
    sources_list.merge!({self.source => self.categories})
    $redis_rtb.set("feed_url-sources-list", sources_list.to_json)

    #update for title check
    begin
      title_results = JSON.parse($redis_rtb.get("sources_list_title_results"))
      title_results.default = "Others"
    rescue Exception => e
      title_results = {}
    end
    title_results.merge!({self.source => {"check_details" => self.check_details}})
    $redis_rtb.set("sources_list_title_results", title_results.to_json)
  end

  def self.get_source_category_with_paginations()
    source_categories = {}
    SourceCategory.all.map {|f| source_categories.merge!({f.source => {"pattern" => f.pattern}})}
    source_categories
  end
end
