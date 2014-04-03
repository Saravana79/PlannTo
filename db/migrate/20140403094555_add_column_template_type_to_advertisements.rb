class AddColumnTemplateTypeToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :template_type, :string
  end
end
