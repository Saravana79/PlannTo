class AddColumnTargetAudience < ActiveRecord::Migration
  def up
    add_column :advertisements, :target_audience, :string
  end

  def down
    remove_column :advertisements, :target_audience
  end
end
