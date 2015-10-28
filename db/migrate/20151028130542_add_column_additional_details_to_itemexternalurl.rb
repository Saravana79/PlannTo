class AddColumnAdditionalDetailsToItemexternalurl < ActiveRecord::Migration
  def change
    add_column :itemexternalurls, :additional_details, :string
  end
end
