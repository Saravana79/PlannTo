class AddColumnEcpmAndEctrToAdvertisements < ActiveRecord::Migration
  def change
    add_column :advertisements, :ecpm, :decimal
    add_column :advertisements, :ectr, :decimal
  end
end
