class ChangeFieldTypeInInvitations < ActiveRecord::Migration
  def change
    change_column :invitations, :follow_type, :string
    change_column :invitations, :item_type, :string
  end
 
end
