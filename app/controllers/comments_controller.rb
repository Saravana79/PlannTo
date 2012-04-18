class CommentsController < ApplicationController

  def create
    @detail = params[:detail]
    @content= Content.find(params[:content_id])
    @comment = Comment.new(params[:comment])
    @comment.commentable = @content
    @comment.user = current_user

    if @comment.save
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
    @content= Content.find(params[:content_id])
    @page =  params[:page].blank? ? 1 : params[:page].to_i
    per_page = 5 
    @previous = (@content.comments.count - per_page * @page )> 0 ? true : false
    @comments= @content.comments.paginate(:page => @page, :per_page => 5)
    @comments_string = render_to_string :partial => "comments", :locals => { :comments => @comments , :page => @page, :content => @content, :previous  => @previous} 
  end
end
