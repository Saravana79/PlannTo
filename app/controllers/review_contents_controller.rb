class ReviewContentsController < ApplicationController
  before_filter :authenticate_user!
	def create
		@reviewcontent = ReviewContent.new(params['review_content'])
    @reviewcontent.ip_address = request.remote_ip
		@reviewcontent.user = current_user
		unless params[:content_create_form_type] == "Popup"
		item_id = params['item_id']
		@item = Item.find item_id
		@reviewcontent.save_with_items!(item_id)
		else
		  @reviewcontent.save_with_items!(params[:review_item_id])
		  @item = Item.find params[:review_item_id] unless params[:review_item_id].blank?
		end
		@item.add_new_rating @reviewcontent.rating if @item

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
    per_page = params[:per_page].present? ? params[:per_page] : 5
    page_no  = params[:page_no].present? ? params[:page_no] : 1
   # @items = Item.where("id in (#{@content.related_items.collect(&:item_id).join(',')})")
   frequency = ((@content.title.split(" ").size) * (0.3)).to_i
    results = Sunspot.more_like_this(@content) do
      minimum_term_frequency 1
      boost_by_relevance true
      minimum_word_length 2
      paginate(:page => page_no, :per_page => per_page)
    end
    @related_contents = results.results
  end
  
  def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
  end

end
