class AddGuideToViews < ActiveRecord::Migration
  VIEWS = ["AnswerContent", "ArticleContent", "ImageContent", "QuestionContent", "ReviewContent"]
  
  def change
  	VIEWS.each do |content|
  		drop_citier_view(content.constantize)
    	create_citier_view(content.constantize)
  	end
  end
end
