class ReviewContentsController < ApplicationController
  before_filter :authenticate_user!
	def create
		@reviewcontent = ReviewContent.new(params['review_content'])
		@reviewcontent.user = current_user
		item_id = params['item_id']
		@item = Item.find item_id
		@reviewcontent.save_with_items!(item_id)
		@item.add_new_rating @reviewcontent.rating

    #Point.add_point_system(current_user, @reviewcontent, Point::PointReason::CONTENT_SHARE) unless @reviewcontent.errors.any?
		#@item.rate_it params['review_content']['rating'],@reviewcontent.user
    #		respond_to do |format|
    #			format.html
    #			format.js
    #		end
	
	end

  def update
    @reviewcontent = Content.find(params[:id])
    @reviewcontent.update_with_items!(params['review_content'], params[:item_id])
  end

end
