class CreateCookieMatches < ActiveRecord::Migration
  def change
    create_table :cookie_matches do |t|
      t.string :plannto_user_id
      t.string :google_user_id
      t.string :match_source
      t.timestamps
    end
  end
end
