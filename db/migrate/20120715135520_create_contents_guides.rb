class CreateContentsGuides < ActiveRecord::Migration
  def change
    create_table :contents_guides do |t|
      t.references :content
	  t.references :guide

      t.timestamps
    end
  end
end
