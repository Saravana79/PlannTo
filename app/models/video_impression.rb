class VideoImpression < ActiveRecord::Base
  include ActiveUUID::UUID
  self.primary_key = "id"

  attr_accessor :t, :r, :device, :a, :video

  def self.create_new_record(obj_params)
    unless obj_params.is_a?(Hash)
      obj_params = JSON.parse(obj_params)
    end
    obj_params = obj_params.symbolize_keys

    vi = VideoImpression.new
    vi.id = obj_params[:video_impression_id]
    vi.advertisement_id = obj_params[:advertisement_id]
    vi.advertisement_type = obj_params[:advertisement_type]
    vi.hosted_site_url = obj_params[:request_referer]
    vi.item_id = obj_params[:itemid]
    vi.impression_time = obj_params[:time]

    unless obj_params[:user].nil?
      vi.user_id = obj_params[:user]
    end
    vi.temp_user_id = obj_params[:temp_user_id]

    vi.ip_address = obj_params[:remote_ip]

    vi.itemsaccess = obj_params[:itemsaccess]
    vi.params = obj_params[:params]
    publisher = Publisher.getpublisherfromdomain(obj_params[:request_referer])
    unless publisher.nil?
      vi.publisher_id = publisher.id
    end

    begin
      winning_price = obj_params[:winning_price].blank? ? nil : AddImpression.get_winning_price_value(obj_params[:winning_price])
      vi.winning_price = winning_price
    rescue
      vi.winning_price = nil
    end

    vi.t = obj_params[:t].to_i
    vi.r = obj_params[:r].to_i
    vi.a = obj_params[:a].to_s
    vi.device = obj_params[:device].to_s
    vi.video = obj_params[:video].to_s

    vi.sid = obj_params[:sid]
    vi.created_at = obj_params[:time]
    vi.updated_at = obj_params[:time]
    return vi
  end
  
  def self.add_video_impression_to_resque(param, remote_ip)
    impression_id = SecureRandom.uuid
    impression_params = {:video_impression_id => impression_id, :advertisement_type => param[:type], :request_referer => param[:ref_url], :item_id => param[:item_id],
                         :time => Time.zone.now.utc, :user => nil, :remote_ip => remote_ip, :advertisement_id => param[:ads_id], :winning_price => param[:wp],
                         :sid => param[:sid], :a => param[:a], :params => param[:url_params], :temp_user_id => param[:plan_to_temp_user_id]}.to_json
    Resque.enqueue(CreateImpressionAndClick, 'VideoImpression', impression_params)
    # AddImpression.create_new_record(impression_params)
    return impression_id
  end

end
