class CommentsController < ApplicationController

  def create
    @content= Content.find(params[:content_id])
    @comment = Comment.new(params[:comment])
    @comment.commentable = @content
    @comment.user = current_user

    if @comment.save
       @comment_string = render_to_string :partial => "comment", :locals => { :comment => @comment } 
      respond_to do|format|
        format.js { render :create, :status => 201 }
      end
    end
  end
  
  def index
    @content= Content.find(params[:content_id])
    @comments= @content.comments
    @comments_string = render_to_string :partial => "comments", :locals => { :comments => @comments } 
  end
end
