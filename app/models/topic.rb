class Topic < Item
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :name

   end
   
  def self.topic_clouds(topics,item_type)
    topic_contents_count = item_type.contents.joins("LEFT JOIN `item_contents_relations_cache` ON item_contents_relations_cache.content_id = contents.id LEFT OUTER JOIN topic_itemtype_relations on topic_itemtype_relations.item_id = item_contents_relations_cache.item_id").group('topic_itemtype_relations.item_id').size
     topic_contents_count.delete(nil)
     array = topic_contents_count.sort {|a1,a2| a2[1]<=>a1[1]}
     maxOccurs = array.first[1]
     minOccurs =  array.last[1]
     minFontSize = 15
        maxFontSize = 100
        @topic_cloud_hash = Hash.new(0)
        topics.each do |tag|
          weight = (tag.contents.count-minOccurs).to_f/(maxOccurs-minOccurs)
          size = minFontSize + ((maxFontSize-minFontSize)*weight).round
          @topic_cloud_hash[tag] = size 
       end
      return @topic_cloud_hash
    end 
 end
