class PagesController < ApplicationController
  layout 'product'
  def show
  end


  def upload 
    userImage = UserImage.create(params[:user_image])
    @insertString = "<img src=\"#{userImage.uploaded_image.url(:thumb)}\" />"
    render :layout => false
  end
end
