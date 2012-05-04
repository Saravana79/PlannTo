class ImageContentsController < ApplicationController
  #before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]

  def new
    @image_content = ImageContent.new
  end

  def create
    @image_content = ImageContent.new(params[:image_content])
    respond_to do |format|
      if @image_content.save
        format.html
        format.js 
      end
    end
  end
end
