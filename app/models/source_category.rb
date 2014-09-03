class SourceCategory < ActiveRecord::Base
  validates_uniqueness_of :source
  after_save :check_and_assign_sources_hash_to_cache_from_table

  def self.update_all_to_cache()
    results = {}
    source_categories = SourceCategory.all
    source_categories.map {|each_feed_url|  each_feed_url.attributes}.select {|each_src| results.merge!({each_src["source"] => each_src["categories"]})}
    results.default = "Others"
    Rails.cache.write("feed_url-sources-list", results)
  end

  def check_and_assign_sources_hash_to_cache_from_table()
    sources_list = Rails.cache.read("feed_url-sources-list")
    sources_list = sources_list.blank? ? {} : sources_list
    sources_list = sources_list.merge({self.source => self.categories})
    Rails.cache.write("feed_url-sources-list", sources_list)
  end
end
