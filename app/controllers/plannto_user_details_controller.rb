class PlanntoUserDetailsController < ApplicationController

  def index
    unless params[:plannto_user_id].blank?
      begin
        @plannto_user_detail = PlanntoUserDetail.where(:plannto_user_id => params[:plannto_user_id]).to_a.last
        @plannto_user_detail = @plannto_user_detail.attributes
      rescue Exception => e
        @plannto_user_detail = {}
        @plannto_user_detail = {"_id"=>"556856bc8109c24dc0000136", "plannto_user_id"=>"50aad253138f06a40b1c3c0dd39d9a701f5c6b0a", "google_user_id"=>"CAESEKWpPFq0fhJ1L9rLYDUwxdU", "lad"=>123, "m_item_types"=>[{"_id"=>"556856bd8109c24dc0000137", "itemtype_id"=>6, "click_item_ids"=>[21800, 26280], "lcd"=>789, "r"=>false, "list_of_urls"=>["http://www.youtube.com/video/qUWO1Ec057E", "http://www.gsmarena.com/nokia_lumia_735-6639.php"], "m_items"=>[{"_id"=>"557c02431f5d550a3a0015d2", "item_id"=>26280, "lad"=>123, "ranking"=>50}, {"_id"=>"557c251f658476baa300324d", "item_id"=>22882, "lad"=>235, "ranking"=>10}], "order_item_ids"=>[26280], "lod"=>123}], "loc_id"=>"29283"}
      end
    end
    render :layout => false
  end
end
