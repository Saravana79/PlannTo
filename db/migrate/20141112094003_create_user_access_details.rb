class CreateUserAccessDetails < ActiveRecord::Migration
  def change
    create_table :user_access_details do |t|
      t.string :plannto_user_id
      t.string :ref_url
      t.string :source
      t.string :additional_details
      t.timestamps
    end
  end
end
