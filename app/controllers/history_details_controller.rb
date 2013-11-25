class HistoryDetailsController < ApplicationController

  def index
    url = ""

      req_url = request.referer
      unless req_url.nil?
        if request.referer.include? "plannto.com" or request.referer.include? "localhost"
          if(params["req"].present? && params["req"] != "")
            req_url = params["req"]
          end
        end
      end 
      publisher = Publisher.getpublisherfromdomain(req_url)


     if params[:id].present?
      @article_details = ArticleContent.find_by_id(params[:id])
    #   base_uri, params = @article_details.url.split("?")
       url = "#{@article_details.url}"
       host = URI.parse(url).host.downcase rescue ""
       domain = host.start_with?('www.') ? host[4..-1] : host      
       @vd = VendorDetail.where(baseurl: domain)
       unless @vd.empty?            
        vendor = Item.find(@vd[0].item_id)
        vendor_id = vendor.id
       end
       @impression_id = "123"
       Click.save_click_data(url,req_url,Time.now,@article_details.id,current_user,request.remote_ip,@impression_id,publisher,vendor_id)
     else

      type = params[:type].present? ? params[:type] : ""
      @impression_id = params[:iid]
      find_item_detail(params[:detail_id], "")
      url = "#{@item_detail.url}"
      vendor = Item.find(@item_detail.site)
      Click.save_click_data(@item_detail.url,req_url,Time.now,@item_detail.itemid,current_user,request.remote_ip,@impression_id,publisher,vendor.id)
    end

    
    unless vendor.nil?  
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
    end
      redirect_to url    
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
