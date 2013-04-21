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
      @insertString = "<div class=\"contentinsertdiv\"><img src=\"#{image.photo.url(:large)}\" class=\"contentInsertImg\" /></div>"
    end
     render :layout => false
   end
  
  def tag
    @item = Item.find(params[:item_id]) if params[:item_id]!=""
    @item = Content.find(params[:content_id]) if params[:content_id]!=""
    if @item.is_a?Item
      @insertString = "<a href=\"#{@item.get_url}\" data-mce-href=\"#{@item.get_url}\"> #{@item.name}</a>"
    else
       @insertString = "<a href=\"#{content_path(@item)}\" data-mce-href=\"#{content_path(@item)}\"> #{@item.title}</a>" 
    end    
    render :layout => false
  end
  
  def autocomplete_tag
    
    if params[:type]
       search_type = Product.follow_search_type(params[:type])
    elsif params[:content] == "true"
      search_type = Product.search_type(params[:search_type]) + [Content]
    else
      search_type = Product.search_type(params[:search_type])
   end 
    @items = Sunspot.search(search_type) do
      keywords params[:term].gsub("-",""), :fields => :name
      with :status,[1,2,3]
      paginate(:page => 1, :per_page => 10) 
      order_by :orderbyid , :asc
      order_by :created_at, :desc            
      #order_by :status,:asc
    end
    if params[:from_profile]
      exclude_selected = Follow.for_follower(current_user).where(:followable_type => params[:search_type]).collect(&:followable) rescue []
      @items = @items.results - exclude_selected
    else
      @items = @items.results
    end
    results = @items.collect{|item|
    # if item.type == "CarGroup"
     #   type = "Car"
     # else
    if(item.is_a? (Product))
        type = item.type.humanize
     elsif(item.is_a? (Content))
        type = item.sub_type   
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
    if  item.is_a?(Item)
      image_url = item.image_url(:small) rescue ""
      url = item.get_url() rescue ""
      # image_url = item.image_url
      {:id => item.id, :value => "#{item.name}", :imgsrc =>image_url, :type => type, :url => url }
       
    else
      image_url = item.content_photos.first.photo.url(:thumb) rescue "/images/prodcut_reivew.png"
      url = content_path(item)
      # image_url = item.image_url
      {:content_id => item.id, :value => Content.title_display(item.title), :imgsrc =>image_url, :type => type, :url => url } 
       end
    }

    
    render :json => results
    
  end

end
