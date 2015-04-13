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
    render :layout => false
  end
end