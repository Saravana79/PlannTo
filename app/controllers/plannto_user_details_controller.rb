class PlanntoUserDetailsController < ApplicationController

  def index
    if !params[:pid].blank?
      begin
        @plannto_user_detail = PUserDetail.where(:pid => params[:pid]).to_a.last
        @plannto_user_detail = @plannto_user_detail.blank? ? {} : @plannto_user_detail.attributes
      rescue Exception => e
        @plannto_user_detail = {}
        # @plannto_user_detail = {"_id"=>"556856bc8109c24dc0000136", "pid"=>"50aad253138f06a40b1c3c0dd39d9a701f5c6b0a", "gid"=>"CAESEKWpPFq0fhJ1L9rLYDUwxdU", "lad"=>123, "i_types"=>[{"_id"=>"556856bd8109c24dc0000137", "itemtype_id"=>6, "ci_ids"=>[21800, 26280], "lcd"=>789, "r"=>false, "lu"=>["http://www.youtube.com/video/qUWO1Ec057E", "http://www.gsmarena.com/nokia_lumia_735-6639.php"], "m_items"=>[{"_id"=>"557c02431f5d550a3a0015d2", "item_id"=>26280, "lad"=>123, "rk"=>50}, {"_id"=>"557c251f658476baa300324d", "item_id"=>22882, "lad"=>235, "rk"=>10}], "o_ids"=>[26280], "lod"=>123}], "lid"=>"29283"}
        @plannto_user_detail = {"Error" => "while fetching record"}
      end
    elsif !params[:gid].blank?
      begin
        @plannto_user_detail = PUserDetail.where(:gid => params[:gid]).to_a.last
        @plannto_user_detail = @plannto_user_detail.blank? ? {} : @plannto_user_detail.attributes
      rescue Exception => e
        @plannto_user_detail = {}
        @plannto_user_detail = {"Error" => "while fetching record"}
        # @plannto_user_detail = {"_id"=>"556856bc8109c24dc0000136", "pid"=>"50aad253138f06a40b1c3c0dd39d9a701f5c6b0a", "gid"=>"CAESEKWpPFq0fhJ1L9rLYDUwxdU", "lad"=>123, "i_types"=>[{"_id"=>"556856bd8109c24dc0000137", "itemtype_id"=>6, "ci_ids"=>[21800, 26280], "lcd"=>789, "r"=>false, "lu"=>["http://www.youtube.com/video/qUWO1Ec057E", "http://www.gsmarena.com/nokia_lumia_735-6639.php"], "m_items"=>[{"_id"=>"557c02431f5d550a3a0015d2", "item_id"=>26280, "lad"=>123, "rk"=>50}, {"_id"=>"557c251f658476baa300324d", "item_id"=>22882, "lad"=>235, "rk"=>10}], "o_ids"=>[26280], "lod"=>123}], "lid"=>"29283"}
      end
    else
      @plannto_user_detail = {"Error" => "Try to use pid=xxx or gid=xxx"}
    end

    #Sort m_items by rank
    begin
      @plannto_user_detail["i_types"].each_with_index do |each_i_type, index|
        each_i_type["m_items"] = each_i_type["m_items"].sort_by {|each_rec| each_rec["rk"].to_i}.reverse
      end
    rescue Exception => e
      @plannto_user_detail = @plannto_user_detail
    end

    render :layout => false
  end
end
