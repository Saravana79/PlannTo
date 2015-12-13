class AddIndexForImpressionMissing < ActiveRecord::Migration
  def up
    add_index :impression_missings, [:hosted_site_url, :req_type]
  end

  def down
    remove_index :impression_missings, [:hosted_site_url, :req_type]
  end
end
