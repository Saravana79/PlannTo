class PagesController < ApplicationController

  def hawgy_page
    @item_details = []
    # if params[:item_type].blank?
    #   @categories = Itemdetail.get_auto_categories()
    # end
    @categories = Itemdetail.get_auto_categories()
    item_type = params[:item_type] ||= "Paint & Exterior Care"
    @item = ItemtypeTag.where(:name => "CarAccessory").last
    @item_details = Itemdetail.where("category like '%#{item_type}%'").paginate(:page => params[:page], :per_page => 4)
    render :layout => false
  end
end