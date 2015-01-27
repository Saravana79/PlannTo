class VideoImpression < ActiveRecord::Base
  include ActiveUUID::UUID
  self.primary_key = "id"

  def self.create_new_record(obj_params)
    unless obj_params.is_a?(Hash)
      obj_params = JSON.parse(obj_params)
    end
    obj_params = obj_params.symbolize_keys

    vi = VideoImpression.new
    vi.id = obj_params[:video_impression_id]
    vi.advertisement_id = obj_params[:advertisement_id]
    vi.type = obj_params[:type]
    vi.ref_url = obj_params[:ref_url]
    vi.item_id = obj_params[:itemid]
    vi.impression_time = obj_params[:time]
    vi.ip_address = obj_params[:remote_ip]

    begin
      winning_price = obj_params[:winning_price].blank? ? nil : AddImpression.get_winning_price_value(obj_params[:winning_price])
      vi.winning_price = winning_price
    rescue
      vi.winning_price = nil
    end
    vi.sid = obj_params[:sid]
    vi.created_at = obj_params[:time]
    vi.updated_at = obj_params[:time]
    return vi
  end
  
  def self.add_video_impression_to_resque(param, remote_ip)
    impression_id = SecureRandom.uuid
    impression_params = {:video_impression_id => impression_id, :type => param[:type], :ref_url => param[:ref_url], :item_id => param[:item_id], :time => Time.zone.now.utc, :remote_ip => remote_ip, :advertisement_id => param[:ads_id], :winning_price => param[:wp], :sid => param[:sid], :a => a}.to_json
    Resque.enqueue(CreateImpressionAndClick, 'VideoImpression', impression_params)
    # AddImpression.create_new_record(impression_params)
    return impression_id
  end
end
