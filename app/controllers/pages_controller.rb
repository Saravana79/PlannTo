class PagesController < ApplicationController

  def estore_plugin
    @item_details = []
    # if params[:item_type].blank?
    #   @categories = Itemdetail.get_auto_categories()
    # end
    @categories = Itemdetail.get_auto_categories()
    item_type = params[:item_type] ||= "Paint & Exterior Care"
    @item = ItemtypeTag.where(:name => "CarAccessory").last
    item_type = CGI.unescape_html(item_type)
    @item_details = Itemdetail.where("category like '%#{item_type}%'").paginate(:page => params[:page], :per_page => 12)
    @search = false
    render :layout => false
  end

  def estore_search
    @item_details, @more_items = Item.get_amazon_products_from_keyword_for_estore(params[:keywords].to_s)
    @search = true
    @search_header = "Search Results for (#{params[:keywords].to_s})"
  end
end