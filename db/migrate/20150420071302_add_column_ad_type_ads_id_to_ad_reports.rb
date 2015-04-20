class AddColumnAdTypeAdsIdToAdReports < ActiveRecord::Migration
  def change
    add_column :ad_reports, :ad_type, :string
    add_column :ad_reports, :ad_ids, :string
  end
end
