class ContentItemRelation < ActiveRecord::Base
  	belongs_to :item
  	belongs_to :content
  	validates_presence_of :item_id, :content_id
  	
  	def get_hierarchy_sql_for_new_content(attribute_tags,relation,level =1)
      if attribute_tags.blank?
        str="
        INNER JOIN
        (select distinct `id` from cache_item_relations where related_id = #{self.item_id})"
      else
      str="
      INNER JOIN
      (select id, count(id) as cnt from cache_item_relations
      where related_id in (#{attributetags}) and relation =#{relation}
      and id in (select distinct `id` from cache_item_relations where related_id = #{self.item_id})
       group by id
       having cnt >= #{attributetags.size})"
       end
       str+=" as table_#{level} on table_#{level}.id=table_#{level-1}.id "
       str
    end
end
