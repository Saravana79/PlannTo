class CreateTopContributorView < ActiveRecord::Migration
  def up
    create_view :view_top_contributors, "SELECT user_id, item_id, sum(points) from points p inner join content_item_relations r on p.object_id = r.content_id where p.object_type = 'Content' group by item_id, user_id order by sum(points)" do |t|
      t.column :user_id
      t.column :item_id
      t.column :points
    end
  end

  def down
    drop_view :view_top_contributors
  end
end
