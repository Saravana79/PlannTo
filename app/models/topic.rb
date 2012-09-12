class Topic < Item
  searchable :auto_index => true, :auto_remove => true  do
    text :name , :boost => 4.0,  :as => :name_ac
    string :name

   end
   
  def self.topic_clouds(item_type)
     topics = ActiveRecord::Base.connection.execute("select i.id, name, count(*) from items i left outer join  item_contents_relations_cache c  on i.id = c.item_id inner join topic_itemtype_relations ti on ti.item_id = i.id  where  i.type ='Topic' and ti.itemtype_id = #{item_type.id} group by c.item_id")
     array = topics.sort {|a1,a2| a2[2]<=>a1[2]}
     maxOccurs = array.first[2]
     minOccurs =  array.last[2]
     minFontSize = 10
     maxFontSize = 40
        @topic_cloud_hash = Hash.new(0)
          array.each do |tag|
          weight = (tag[2]-minOccurs).to_f/(maxOccurs-minOccurs)
          size = minFontSize + ((maxFontSize-minFontSize)*weight).round
          @topic_cloud_hash[[tag[0],tag[2]]]= size 
       end
       return @topic_cloud_hash
    end 
 end
 

