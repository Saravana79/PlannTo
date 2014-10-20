require "securerandom"

class HistoryDetailsController < ApplicationController

  def index
    params[:is_test] ||= 'false'
    cookies[:plan_to_temp_user_id] = {value: SecureRandom.hex(20), expires: 1.year.from_now} if cookies[:plan_to_temp_user_id].blank?
    temp_user_id = cookies[:plan_to_temp_user_id];
    url = ""

    req_url = request.referer
    unless req_url.nil?
      if request.referer.include? "plannto.com" or request.referer.include? "localhost"
        if (params["req"].present? && params["req"] != "")
          req_url = params["req"]
        end
      end
    end

    req_url = params[:ref_url].blank? ? req_url : params[:ref_url]

    publisher = Publisher.getpublisherfromdomain(req_url)


    if params[:id].present?
      @article_details = ArticleContent.find_by_id(params[:id])
      #   base_uri, params = @article_details.url.split("?")
      url = "#{@article_details.url}"
      domain = VendorDetail.getdomain(url)
      @vd = VendorDetail.where(baseurl: domain)
      unless @vd.empty?
        vendor = Item.find(@vd[0].item_id)
        vendor_id = vendor.id
      end
      @impression_id = "123"
      # Click.save_click_data(url, req_url, Time.zone.now, @article_details.id, current_user, request.remote_ip, @impression_id, publisher, vendor_id, "Offer", temp_user_id)

      click_params =  {:url => url, :request_referer => req_url, :time => Time.zone.now, :item_id => @article_details.id, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => @impression_id,
                       :publisher => publisher.blank? ? nil : publisher.id, :vendor_id => vendor_id, :source_type => "Offer", :temp_user_id => temp_user_id, :advertisement_id => params[:ads_id], :sid => params[:sid]}.to_json
      Resque.enqueue(CreateImpressionAndClick, 'Click', click_params) if params[:is_test] != "true"
    else

      type = params[:type].present? ? params[:type] : ""

      if (type == "Hotel")
        @impression_id = params[:iid].present? ? params[:iid] : "0"
        find_item_detail(params[:detail_id], 'Hotel')
        if !params[:ads_id].blank? || @item_detail.blank?
          @ad = Advertisement.where("id = ? and review_status='approved'", params[:ads_id]).first
          url = @ad.click_url
        else
            url = "#{@item_detail.url}"
        end

        item_id = @item_detail.blank? ? "" : @item_detail.item_id

        unless @item_detail.blank?
          vendor = @item_detail.vendor
        end

        vendor_id = vendor.blank? ? "" : vendor.id

        # Click.save_click_data(url, req_url, Time.zone.now, item_id, current_user, request.remote_ip, @impression_id, publisher, vendor_id, "PC", temp_user_id)

        click_params =  {:url => url, :request_referer => req_url, :time => Time.zone.now, :item_id => item_id, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => @impression_id,
                         :publisher => publisher.blank? ? nil : publisher.id, :vendor_id => vendor_id, :source_type => "PC", :temp_user_id => temp_user_id, :advertisement_id => params[:ads_id], :sid => params[:sid]}.to_json
        Resque.enqueue(CreateImpressionAndClick, 'Click', click_params) if params[:is_test] != "true"
      else
        @impression_id = params[:iid].present? ? params[:iid] : "0"
        find_item_detail(params[:detail_id], type)
        if !params[:ads_id].blank? && @item_detail.blank?
          @ad = Advertisement.where("id = ? and review_status='approved'", params[:ads_id]).first
          url = @ad.click_url
        else
          url = "#{@item_detail.url}"
        end

        item_id = @item_detail.blank? ? "" : @item_detail.itemid

        domain = VendorDetail.getdomain(url)
        @vd = VendorDetail.where(baseurl: domain)
        unless @vd.empty?
          vendor = Item.find(@vd[0].item_id)
        end

        vendor_id = vendor.blank? ? "" : vendor.id

        vendor = @item_detail.blank? ? nil : Item.find_by_id(@item_detail.site)

        click_params =  {:url => url, :request_referer => req_url, :time => Time.zone.now, :item_id => item_id, :user => current_user.blank? ? nil : current_user.id, :remote_ip => request.remote_ip, :impression_id => @impression_id,
                         :publisher => publisher.blank? ? nil : publisher.id, :vendor_id => vendor_id, :source_type => "PC", :temp_user_id => temp_user_id, :advertisement_id => params[:ads_id], :sid => params[:sid]}.to_json
        Resque.enqueue(CreateImpressionAndClick, 'Click', click_params) if params[:is_test] != "true"

        # if type == "advertisement"
          # Click.save_click_data(url, req_url, Time.zone.now, item_id, current_user, request.remote_ip, @impression_id, publisher, vendor_id, "PC", temp_user_id)


          # click_params =  {:url => url, :request_referer => req_url, :time => Time.zone.now, :item_id => item_id, :user => current_user.id, :remote_ip => request.remote_ip, :impression_id => @impression_id,
          #                  :publisher => publisher.blank? ? nil : publisher.id, :vendor_id => vendor_id, :source_type => "PC", :temp_user_id => temp_user_id}.to_json
          # Resque.enqueue(CreateImpressionAndClick, 'Click', click_params)
        # else
        #   Click.save_click_data(url, req_url, Time.zone.now, item_id, current_user, request.remote_ip, @impression_id, publisher, vendor_id, "PC", temp_user_id)
        # end
      end
    end


    unless vendor.nil?
      if !vendor.vendor_detail.params.nil? || !vendor.vendor_detail.params.blank?
        url = vendor.vendor_detail.params.gsub(/\{url}/, url)
        unless publisher.nil?
          pv = PublisherVendor.where(:vendor_id => vendor.id, :publisher_id => publisher.id).first
        end
        if !pv.nil?
          url = url.gsub(/\{affid}/, pv.affliateid) unless pv.affliateid.nil?
          url= url.gsub(/\{trackid}/, pv.trackid) unless pv.trackid.nil?
        else
          pv = PublisherVendor.where(:publisher_id => 0, :vendor_id => vendor.id).first
          if !pv.nil?
            url = url.gsub(/\{affid}/, pv.affliateid) unless pv.affliateid.nil?
            url= url.gsub(/\{trackid}/, pv.trackid) unless pv.trackid.nil?
          end
        end
        url= url.gsub(/\{iid}/, @impression_id) unless @impression_id.nil?
      end
    end
    url= url.gsub(/\{iid}/, @impression_id) unless @impression_id.nil?
      # if ((vendor.id == 9874 || vendor.id == 9858 ) && (item_id == 22988|| item_id ==22800 || item_id == 15404 || item_id == 15434 || item_id == 21986))
      #   url = url.gsub("offer_id=17","offer_id=21")
      # end 

      #for flipkart support
      if(vendor && vendor.id == 9861)
          url = url.gsub("www.flipkart.com","dl.flipkart.com/dl")
      end
      redirect_to url
  end

  private

  def find_item_detail(detail_id, type)
    @item_detail = case type
                     when "Content" then
                       Content.find_by_id(detail_id)
                     when "Hotel" then
                       HotelVendorDetail.find_by_id(detail_id)
                     else
                       Itemdetail.find_by_item_details_id(detail_id)
                   end


  end
end
