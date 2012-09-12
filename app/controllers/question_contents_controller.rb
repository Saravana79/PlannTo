class QuestionContentsController < ApplicationController
  
  before_filter :authenticate_user!
  # => skip_before_filter :verify_authenticity_token
  layout :false

	def create
    @item = Item.find(params[:question_content][:itemtype_id])
		@questioncontent = QuestionContent.new params[:question_content]
    @questioncontent.ip_address = request.remote_ip
		@questioncontent.user = current_user
		#@item = Item.find params['item_id']
		@questioncontent.save_with_items!(params['item_id'])
    
  end

	def show
		@questioncontent = QuestionContent.find params[:id]
		@item = @questioncontent.items[0]
		respond_to do |format|
			format.html
			format.js
		end
	end

  def update
    @content = Content.find(params[:id])
    @content.ip_address = request.remote_ip
    @detail = params[:detail]
    @content.update_with_items!(params['question_content'], params[:item_id])
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
