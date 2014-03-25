class AddColumnsSuggestionIdAndNameToSourceitems < ActiveRecord::Migration
  def change
    add_column :sourceitems, :suggestion_id, :integer
    add_column :sourceitems, :suggestion_name, :string
  end
end
