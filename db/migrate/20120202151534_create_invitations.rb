class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.integer :sender_id,       :null =>false
      t.integer :item_id       
      t.integer :item_type
      t.string :email,          :null => false, :limit => 255
      t.integer :follow_type,   :null => false
      t.string :message,        :limit => 2000
      t.string :token,          :null => false
      t.string :user_ip,        :null => false
      
      t.timestamps
    end
  end
end
