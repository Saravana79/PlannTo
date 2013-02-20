class ImageuploadsController < ApplicationController
  layout 'product'
  skip_before_filter :verify_authenticity_token
  def show
  end


  def upload 
    if params[:content_photo]
      image = ContentPhoto.new
      image.photo = params[:content_photo][:photo] 
      image.save
      @insertString = "<img src=\"#{image.photo.url(:large)}\" class=\"contentInsertImg\" />"
    end
     render :layout => false
   end
  
   def tag
    @item = Item.find(params[:item_id])
    @insertString = "<a href=\"#{@item.get_url}\" /> #{@item.name}</a>"
    render :layout => false
  end
   def autocomplete_tag
   if params[:type]
     search_type = Product.wizared_search_type(params[:type])
   else  
     search_type = Product.search_type(params[:search_type])
   end 
    @items = Sunspot.search(search_type) do
      keywords params[:term], :fields => :name
      paginate(:page => 1, :per_page => 10)        
    end

    if params[:from_profile]
      exclude_selected = Follow.for_follower(current_user).where(:followable_type => params[:search_type]).collect(&:followable)
      @items = @items.results - exclude_selected
    else
      @items = @items.results
    end

    results = @items.collect{|item|

      image_url = item.image_url(:small)
     # if item.type == "CarGroup"
     #   type = "Car"
     # else
     
     
     
     if(item.is_a? (Product))
        type = item.type.humanize
     elsif(item.is_a? (CarGroup))
        type = "Groups"
     elsif(item.is_a? (AttributeTag))
        type = "Groups"
    elsif(item.is_a? (ItemtypeTag))
        type = "Topics"
     else
        type = item.type.humanize
      end 
    
     # end
      url = item.get_url()
      # image_url = item.image_url
      {:id => item.id, :value => "#{item.name}", :imgsrc =>image_url, :type => type, :url => url }
    }
    render :json => results
    
  end
end
