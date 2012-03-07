class CreateTopContributors < ActiveRecord::Migration
  def change
    #SELECT item_id, user_id, sum(points) from points p inner join content_item_relations r on p.object_id = r.content_id where p.object_type = 'Content' group by item_id, user_id order by sum(points)
    create_table :top_contributors do |t|
      t.integer :user_id
      t.integer :item_id
      t.integer :rank

      t.timestamps
    end
  end
end
