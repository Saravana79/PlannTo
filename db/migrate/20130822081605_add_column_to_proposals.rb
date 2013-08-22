class AddColumnToProposals < ActiveRecord::Migration
  def change
    rename_column :proposals, :comments, :comment
    add_column  :proposals,:comments_count,:integer
  end
end
