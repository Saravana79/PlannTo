class ReviewContentsController < ApplicationController

	def create
		@reviewcontent = ReviewContent.new(params['review_content'])
		@reviewcontent.user = User.first
		item_id = params['item_id']
		@reviewcontent.save_with_items!(item_id)
    Point.add_point_system(current_user, @reviewcontent, Point::PointReason::CONTENT_SHARE) unless @reviewcontent.errors.any?
		#if @reviewcontent.save
			respond_to do |format|
				format.html
				format.js
			end
		#end
	end	

end
