class AddClickSourceTypeToClicks < ActiveRecord::Migration
  def change
    add_column :clicks, :source_type, :string
  end
end
