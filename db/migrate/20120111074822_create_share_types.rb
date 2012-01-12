class CreateShareTypes < ActiveRecord::Migration
  def change
    create_table :share_types do |t|
      t.string :name
      t.timestamps
      #ShareType.create(:name => "Tips")
      #ShareType.create(:name => "Review")
      #ShareType.create(:name => "News")
      #ShareType.create(:name => "Q&A")
      #ShareType.create(:name => "Support")
    end
  end
end
