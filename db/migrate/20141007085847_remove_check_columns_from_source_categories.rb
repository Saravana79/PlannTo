class RemoveCheckColumnsFromSourceCategories < ActiveRecord::Migration
  def up
    remove_column :source_categories, :have_mobile_site, :is_having_pagination, :title_check, :generic_check
  end

  def down
    add_column :source_categories, :title_check, :boolean
    add_column :source_categories, :generic_check, :boolean
    add_column :source_categories, :is_having_pagination, :boolean, :default => false
    add_column :source_categories, :have_mobile_site, :boolean, :default => false
  end
end
