class ImageuploadsController < ApplicationController
  layout 'product'
  skip_before_filter :verify_authenticity_token
  def show
  end


  def upload 
    image = ContentPhoto.new
    image.photo = params[:content_photo][:photo]
    image.save
    @insertString = "<img src=\"#{image.photo.url(:thumb)}\" />"
    render :layout => false
  end
  
   def tag
    @item = Item.find(params[:item_id])
    @insertString = "<a href=\"/#{@item.get_url}\" /> pppppp </a>"
    render :layout => false
  end
end
