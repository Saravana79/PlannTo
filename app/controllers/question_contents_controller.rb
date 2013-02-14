class QuestionContentsController < ApplicationController
  
  before_filter :authenticate_user!
  # => skip_before_filter :verify_authenticity_token
  layout :false

	def create
    #@item = Item.find(params[:question_content][:itemtype_id])
		@questioncontent = QuestionContent.new params[:question_content]
    @questioncontent.ip_address = request.remote_ip
		@questioncontent.user = current_user
		@item = Item.find params['item_id']
		@questioncontent.save_with_items!(params['item_id'])
    UserActivity.save_user_activity(current_user,@questioncontent.id,"created",@questioncontent.sub_type,@questioncontent.id,request.remote_ip)           
   Follow.content_follow(@questioncontent,current_user) if @questioncontent.id!=nil
   if current_user.total_points < 10
		  @questioncontent.update_attribute('status',2) 
		  @display = 'false'
	 else 
	    Point.add_point_system(current_user, @questioncontent, Point::PointReason::CONTENT_CREATE)
	 end   
   if @questioncontent
    session[:content_id] = @questioncontent.id
    @facebook_post = params[:facebook_post]
  end
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
    @popular_items = Item.find_by_sql("select * from items where id in (select item_id from item_contents_relations_cache where content_id =#{@content.id}) and itemtype_id in (1, 6, 12, 13, 14, 15) and status in ('1','2')  order by id desc limit 4")
    @popular_items_ids  = @popular_items.map(&:id).join(",")
    @related_contents = results.results
  end
  
  def destroy
    @content = Content.find(params[:id])
    @content.update_attribute(:status, Content::DELETE_STATUS)
    @content.remove_user_activities
  end

end
