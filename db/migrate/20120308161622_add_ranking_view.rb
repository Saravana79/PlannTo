class AddRankingView < ActiveRecord::Migration
  def up
    create_view :view_rankings, "SELECT user_id, sum(points) from planntodevelopment.points group by user_id order by sum(points)" do |t|
      t.column :user_id
      t.column :points
    end
  end

  def down
    drop_view :view_rankings
  end
end
