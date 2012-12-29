class CommentsController < ApplicationController
  before_filter :authenticate_user!, :except => :index
  def create
    @detail = params[:detail]
    if params[:comment_type]
    @content= params[:comment_type].camelize.constantize.find(params[:content_id])
    else
      @content= Content.find(params[:content_id])
    end 
    @comment = Comment.new(params[:comment])
    @comment.commentable = @content
    @comment.status = @comment.set_comment_status("create")
    @comment.user = current_user
   
    if @comment.save
    
      if !@content.is_a?UserQuestion and !@content.is_a?UserAnswer
        UserActivity.save_user_activity(current_user,@content.id,"commented",@content.type == "AnswerContent" ? "Answer"  :  @content.sub_type,@comment.id,request.remote_ip) if @comment
        Follow.content_follow(@content.type == "AnswerContent" ? @content.question_content : @content ,current_user) if @comment
      end
        
     if @content.is_a?UserQuestion
        UserActivity.save_user_activity(current_user,@content.buying_plan.id,"commented","Buying Plan",@comment.id,request.remote_ip)
     end  
      
     #if  @content.is_a?UserAnswer
      #  UserActivity.save_user_activity(current_user,@content.id,"commented","Recommend",@comment.id,request.remote_ip)
     #end  
       
      if @detail
        @comment_string = render_to_string :partial => "detailed_comment", :locals => { :comment => @comment }
      else
        @comment_string = render_to_string :partial => "comment", :locals => { :comment => @comment }
      end
      respond_to do|format|
        format.js { render :create, :status => 201 }
      end
    end
  end
  
  def index
    @content= params[:comment_type].camelize.constantize.find(params[:content_id])
    @page =  params[:page].blank? ? 1 : params[:page].to_i
    per_page = 5 
    @previous = (@content.comments.where("status=1").count - per_page * @page )> 0 ? true : false
    @comments= @content.comments.where("status=1").paginate(:page => @page, :per_page => 5)
    @comments_string = render_to_string :partial => "comments", :locals => { :comments => @comments , :page => @page, :content => @content, :previous  => @previous} 
  end
  
  def edit
    @content= Content.find(params[:content_id])
    @comment = Comment.find(params[:id])
    @detail = params[:detail]
    respond_to do|format|
    format.js
  end
  end
  
  def update
    @content = Content.find(params[:content_id])
    @comment = Comment.find(params[:id])
    @detail = params[:detail]
    @comment.update_attributes(params[:comment])
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.update_attribute(:status, Comment::DELETE_STATUS)
    @comment.remove_user_activities
  end
end
