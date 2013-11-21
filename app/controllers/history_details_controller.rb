class HistoryDetailsController < ApplicationController

  def index
    url = ""
    if prams[:id]
      @article_details = ArticleContent.find_by_id(params[:id])
      base_uri, params = @article_details.url.split("?")
      url = "#{@article_details.url}"
      redirect_to url
    else
      type = params[:type].present? ? params[:type] : ""
      @impression_id = params[:iid]
      find_item_detail(params[:detail_id], type)
      url = "#{@item_detail.url}"
      

    
#      @history = HistoryDetail.new(:site_url => @item_detail.url, :ip_address => request.remote_ip, :redirection_time => Time.now)
#      @history.user_id = current_user.id if user_signed_in?    
#      @history.plannto_location = session[:return_to]
  #    @history.save
      req_url = request.referer
      unless req_url.nil?
        if request.referer.include? "plannto.com" or request.referer.include? "localhost"
          if(params["req"].present? && params["req"] != "")
            req_url = params["req"]
          end
        end
      end 
      publisher = Publisher.getpublisherfromdomain(req_url)
      Click.save_click_data(@item_detail.url,req_url,Time.now,@item_detail.itemid,current_user,request.remote_ip,@impression_id,publisher)
      vendor = Item.find(@item_detail.site)
      if !vendor.vendor_detail.params.nil? || !vendor.vendor_detail.params.blank? 
         url = vendor.vendor_detail.params.gsub(/\{url}/,url)
         unless publisher.nil?
            pv = PublisherVendor.where(:vendor_id => vendor.id,:publisher_id => publisher.id).first 
         end
         if !pv.nil?
            url = url.gsub(/\{affid}/,pv.affliateid) unless pv.affliateid.nil?
            url=  url.gsub(/\{trackid}/,pv.trackid)  unless pv.trackid.nil?
         else
           pv = PublisherVendor.where(:publisher_id => 0,:vendor_id => vendor.id).first
          if !pv.nil?
            url = url.gsub(/\{affid}/,pv.affliateid) unless pv.affliateid.nil?
            url=  url.gsub(/\{trackid}/,pv.trackid)  unless pv.trackid.nil? 
          end   
        end
      end
      redirect_to url
    end
  end

  private

  def find_item_detail(detail_id, type)
    @item_detail = case type
    when "Content" then Content.find(detail_id)
    else
      Itemdetail.find(detail_id)
    end
      

  end
end
