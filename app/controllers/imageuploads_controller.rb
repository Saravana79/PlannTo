class ImageuploadsController < ApplicationController
  layout 'product'
  skip_before_filter :verify_authenticity_token
  def show
  end


  def upload 
    image = ContentPhoto.new
    image.photo = params[:file]
    image.save
    @insertString = "<img src=\"#{image.photo.url(:thumb)}\" />"
    render :layout => false
  end
end
