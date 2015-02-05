class AddColumnsToVideoImpression < ActiveRecord::Migration
  def change
    add_column :video_impressions, :publisher_id, :integer
    add_column :video_impressions, :user_id, :integer
    add_column :video_impressions, :itemsaccess, :string
    add_column :video_impressions, :params, :string
    add_column :video_impressions, :temp_user_id, :string
    rename_column :video_impressions,:type, :advertisement_type
    rename_column :video_impressions,:ref_url, :hosted_site_url
  end
end
