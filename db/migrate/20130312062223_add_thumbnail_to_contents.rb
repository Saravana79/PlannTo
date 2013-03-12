class AddThumbnailToContents < ActiveRecord::Migration
  def change
     add_column :review_contents,:thumbnail,:string
     add_column :question_contents,:thumbnail,:string
  end
end
