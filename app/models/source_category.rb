class SourceCategory < ActiveRecord::Base
  after_save :check_and_assign_sources_hash_to_cache_from_table

  def check_and_assign_sources_hash_to_cache_from_table()
    sources_list = Rails.cache.delete("feed_url-sources-list")
    results = {}
    source_categories = SourceCategory.all
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| results.merge!({each_src["source"] => each_src["categories"]})}
    results.default = "Others"
    Rails.cache.write("feed_url-sources-list", results)
  end
end
