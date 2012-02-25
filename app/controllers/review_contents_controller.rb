class ReviewContentsController < ApplicationController

	def create
		@reviewcontent = ReviewContent.new(params['review_content'])
		@reviewcontent.user = User.first
		item_id = params['item_id']
		@reviewcontent.save_with_items!(item_id)
		#if @reviewcontent.save
			respond_to do |format|
				format.html
				format.js
			end
		#end
	end	

end
