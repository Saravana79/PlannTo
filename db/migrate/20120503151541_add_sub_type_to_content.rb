class AddSubTypeToContent < ActiveRecord::Migration
  def change
    add_column :contents, :sub_type, :string
  end
end
