class AddSidToClicks < ActiveRecord::Migration
  def change
    add_column :clicks, :sid, :string
  end
end
