class CommentsController < ApplicationController

  def create
    parent = params[:parent].camelize.constantize.find(params[:parent_id]) unless params[:parent].nil? && params[:parent_id].nil?
    @comment = Comment.new(params[:comment])
    @comment.commentable = parent
    @comment.user = User.find(1)

    if @comment.save
      respond_to do|format|
        format.js { render :create, :status => 201 }
      end
    end
  end
end
