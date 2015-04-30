class AddColumnGoogleMappedToCookieMatches < ActiveRecord::Migration
  def change
    add_column :cookie_matches, :google_mapped, :boolean
  end
end
