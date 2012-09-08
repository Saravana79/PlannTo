class ReviewContentsController < ApplicationController
  before_filter :authenticate_user!
	def create
		@reviewcontent = ReviewContent.new(params['review_content'])
    @reviewcontent.ip_address = request.remote_ip
		@reviewcontent.user = current_user
		item_id = params['item_id']
		@item = Item.find item_id
		@reviewcontent.save_with_items!(item_id)
		@item.add_new_rating @reviewcontent.rating

    respond_to do |format|
      format.js
    end
    
    #Point.add_point_system(current_user, @reviewcontent, Point::PointReason::CONTENT_SHARE) unless @reviewcontent.errors.any?
		#@item.rate_it params['review_content']['rating'],@reviewcontent.user
    #		respond_to do |format|
    #			format.html
    #			format.js
    #		end
	
	end

  def update
    @item = Item.find params['item_id'] unless params[:item_id] == ""
    @content = Content.find(params[:id])
    @detail = params[:detail]
    @content.ip_address = request.remote_ip
    @content.update_with_items!(params['review_content'], params[:item_id])
     results = Sunspot.more_like_this(@content) do
      fields :title
      minimum_term_frequency 1
    end
    @related_contents = results.results
  end
  
  def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
  end

end
