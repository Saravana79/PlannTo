class SourceCategory < ActiveRecord::Base
  validates_uniqueness_of :source
  after_save :check_and_assign_sources_hash_to_cache_from_table

  def self.update_all_to_cache()
    results = {}
    source_categories = SourceCategory.all
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| results.merge!({each_src["source"] => each_src["categories"]})}
    results.default = "Others"
    # Rails.cache.write("feed_url-sources-list", results)
    $redis_rtb.set("feed_url-sources-list", results.to_json)
  end

  def check_and_assign_sources_hash_to_cache_from_table()
    # sources_list = Rails.cache.read("feed_url-sources-list")
    sources_list = JSON.parse($redis_rtb.get("feed_url-sources-list"))
    sources_list.default = "Others"
    sources_list = sources_list.blank? ? {} : sources_list
    sources_list = sources_list.merge({self.source => self.categories})
    # Rails.cache.write("feed_url-sources-list", sources_list)
    $redis_rtb.set("feed_url-sources-list", sources_list.to_json)
  end

  def self.get_source_category_with_paginations()
    source_categories = {}
    SourceCategory.all.map {|f| source_categories.merge!({f.source => {"is_having_pagination" => f.is_having_pagination, "pattern" => f.pattern}})}
    source_categories
  end
end
