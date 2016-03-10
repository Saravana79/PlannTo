class PUserDetail
  include Mongoid::Document
  # include Mongoid::Timestamps::Created
  after_save :update_lad#, :update_duplicate_record

  attr_accessor :skip_callback, :skip_duplicate_update


  # field :plannto_user_id, type: String
  # field :gender, type: String  #value M/F
  # field :google_user_id, type: String
  # field :lad, type: Date #Last acessed date
  # field :m_rank, type: Integer #Male Ranking
  # field :f_rank, type: Integer #Female Ranking
  # field :a, type: String # Additional detail
  # field :loc_id, type: String # Locaiton id
  # field :agg_info, type: String # Aggregated info


  field :pid, type: String #plannto_user_id
  field :gid, type: String #google_user_id
  field :g, type: String  #value M/F
  field :lad, type: Date #Last acessed date
  field :mr, type: Integer #Male Ranking #m_rank
  field :fr, type: Integer #Female Ranking #f_rank
  field :a, type: String # Additional detail
  field :lid, type: String # Locaiton id #loc_id
  field :ai, type: String # Aggregated info #agg_info

  embeds_many :i_types
  # embeds_many :m_items

  index({ pid: 1 })
  index({ gui: 1 })
  index({ lad: 1 })

  def self.update_plannto_user_detail(impression)
    # plannto user details
    if !impression.temp_user_id.blank?
      plannto_user_detail = PUserDetail.where(:pid => impression.temp_user_id).to_a.last

      if (!plannto_user_detail.blank? && plannto_user_detail.gid.blank?)
        cookie_match = CookieMatch.where(:plannto_user_id => impression.temp_user_id).last
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          plannto_user_detail.gid = cookie_match.google_user_id
          plannto_user_detail.save!
        end
      elsif plannto_user_detail.blank?
        plannto_user_detail = PUserDetail.new(:pid => impression.temp_user_id)
        cookie_match = CookieMatch.where(:plannto_user_id => impression.temp_user_id).last
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          plannto_user_detail.gid = cookie_match.google_user_id
        end
        plannto_user_detail.save!
      end
    end

    if !plannto_user_detail.blank?
      agg_info = {}
      new_m_agg_info = ""
      itemtype_id = nil
      #plannto user details
      if !impression.item_id.blank?
        itemtype = Item.where(:id => impression.item_id).select(:itemtype_id).first
        itemtype_id = itemtype.itemtype_id rescue ""
      end

      if !itemtype_id.blank?
        agg_info = {"#{itemtype_id}" => 1}
        new_m_agg_info = "#{itemtype_id}:1"

        i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
        if i_type.blank?
          plannto_user_detail.i_types << IType.new(:itemtype_id => itemtype_id)
          i_type = plannto_user_detail.i_types.where(:itemtype_id => itemtype_id).last
        end

        item_id = impression.item_id

        m_item = i_type.m_items.where(:item_id => item_id).last

        if m_item.blank?
          lad = Date.today
          rk = 30
          i_type.m_items << MItem.new(:item_id => item_id, :lad => lad, :rk => rk)
        else
          m_item.lad = Date.today
          m_item.rk = m_item.rk.to_i + 30
          m_item.save!
        end

        o_ids = i_type.o_ids
        o_ids = o_ids.blank? ? [impression.item_id.to_i] : (o_ids + [impression.item_id.to_i])
        o_ids = o_ids.map(&:to_i).compact.uniq
        i_type.o_ids = o_ids
        i_type.lod = Date.today
        i_type.save!
      end

      if !new_m_agg_info.blank?
        m_agg_info = plannto_user_detail.ai.to_s
        m_agg_info_arr = m_agg_info.split(",")
        m_agg_info_arr << new_m_agg_info
        plannto_user_detail.ai = m_agg_info_arr.uniq.join(",")
      end

      plannto_user_detail.skip_duplicate_update = true
      plannto_user_detail.save!
    end
  end

  def update_additional_details(url)
    domain = Item.get_host_without_www(url)
    resale = false
    male_site_list = ["team-bhp.com", "gadgetstouse.com"]
    female_site_list = ["makeupandbeauty.com", "stylecraze.com", "bollywoodshaadis.com", "southindiafashion.com", "wiseshe.com", "indusladies.com", "celebritysaree.com"]
    resale_site_list = ["olx.in", "quikr.com", "classifieds.team-bhp.com"]
    buying_cycle_site_list = ["mysmartprices.com", "smartprix.com", "pricebaba.com"]

    user_id_for_key = ""
    if self.pid.blank?
      user_id_for_key = self.gid.to_s
      key_prefix = "ubl:#{user_id_for_key}"
    else
      user_id_for_key = self.pid.to_s
      key_prefix = "ubl:pl:#{user_id_for_key}"
    end

    values = $redis_rtb.hgetall(key_prefix)
    values = {} if values.blank?
    redis_rtb = {key_prefix => values}

    redis_rtb_ubl = redis_rtb[key_prefix]

    if male_site_list.include?(domain)
      self.mr = self.mr.to_i + 1
    elsif female_site_list.include?(domain)
      self.fr = self.fr.to_i + 1
    elsif resale_site_list.include?(domain)
      resale = true
      a_hash = self.a.to_s.split("<<").map {|each_v| each_v.split(",")}
      a_hash = Hash[a_hash]
      a_hash.merge!("resale" => "true", "rad" => Date.today.to_s) #rad => resale last accessed date
      a_hash_str = ""
      a_hash.each {|k,v| a_hash_str+="#{k},#{v}<<"}
      self.a = a_hash_str
      # redis_rtb.merge!("#{key_prefix}:ad:rs" => {"val" => Date.today.to_s}) if !key_prefix.blank?
    elsif buying_cycle_site_list.include?(domain)
      a_hash = self.a.to_s.split("<<").map {|each_v| each_v.split(",")}
      a_hash = Hash[a_hash]
      a_hash.merge!("bc" => "true", "bclad" => Date.today.to_s) #bclad => buying cycle last accessed date
      a_hash_str = ""
      a_hash.each {|k,v| a_hash_str+="#{k},#{v}<<"}
      self.a = a_hash_str
      # redis_rtb.merge!("#{key_prefix}:ad:bc" => {"val" => "true"}) if !key_prefix.blank?
      redis_rtb_ubl.merge!("bc" => "true", "bclad" => Date.today.to_s)
    end

    if !self.lid.blank?
      redis_rtb_ubl.merge!("lid" => self.lid)
    end

    if self.mr.to_i > self.fr.to_i
      self.g = "m"
      # redis_rtb.merge!("#{key_prefix}:g" => {"val" => "male"}) if !key_prefix.blank?
      redis_rtb_ubl.merge!("g" => "m")
    elsif self.mr.to_i < self.fr.to_i
      self.g = "f"
      # redis_rtb.merge!("#{key_prefix}:g" => {"val" => "female"}) if !key_prefix.blank?
      redis_rtb_ubl.merge!("g" => "f")
    end

    self.skip_callback = true
    self.skip_duplicate_update = true

    self.save!

    return redis_rtb, resale
  end

  def self.remove_old_records
    # plannto_user_details = PUserDetail.delete_all(:lad.lte => "#{1.month.ago}")

    # heroku run rake db:mongoid:create_indexes
    # plannto_user_details = PUserDetail.destroy_all(conditions: {"lad" => {"$lte" => 1.month.ago}})

    days = [*30..57].reverse

    days.each do |day|
      plannto_user_details = PUserDetail.where("lad" => {"$lte" => "#{day}".to_i.days.ago})
      tot_count = plannto_user_details.count

      plannto_user_details.each do |each_rec|
        begin
          p tot_count
          tot_count = tot_count - 1
          each_rec.delete
        rescue Exception => e
          p "Error"
        end
      end
    end
  end

  private

  def update_lad
    if self.skip_duplicate_update != true
      self.skip_duplicate_update = true
      # update_duplicate_record
    end

    if self.skip_callback != true
      self.skip_duplicate_update = true
      self.skip_callback = true
      self.lad = Time.now
      self.save

      # ActiveRecord::Base.connection.execute("update cookie_matches set updated_at = '#{Time.now.utc}' where plannto_user_id = '#{self.plannto_user_id}'") if !self.plannto_user_id.blank?

      # cookie_match = CookieMatch.where(:plannto_user_id => self.plannto_user_id).last
      # cookie_match.touch if !cookie_match.blank? rescue ""
      #
      # if !self.google_user_id.blank? && !self.plannto_user_id.blank?
      #   $redis_rtb.pipelined do
      #     $redis_rtb.set("cm:#{self.google_user_id}", self.plannto_user_id)
      #     $redis_rtb.expire("cm:#{self.google_user_id}", 2.weeks)
      #   end
      # end
    end
  end

  def update_duplicate_record
    # if self.pid_changed? || self.google_user_id_changed?
      plannto_user_details = PUserDetail.where(:pid => self.pid)
      if plannto_user_details.count > 1
        old_plannto_user_details = plannto_user_details.delete_if {|pud| pud.id == self.id }

        old_plannto_user_details.each do |old_detail|

          if self.google_user_id.blank? && !old_detail.google_user_id.blank?
            self.google_user_id = old_detail.google_user_id
          end

          old_detail.i_types.each do |old_i_type|
            valid_attributes = old_detail.attributes.slice("lid","mr", "g", "ai", "fr", "a")
            valid_attributes.delete_if {|k,v| v.blank?}
            self.update_attributes!(valid_attributes)
            i_type = self.i_types.where(:itemtype_id => old_i_type.itemtype_id).last
            if i_type.blank?
              self.i_types << IType.new(:itemtype_id => old_i_type.itemtype_id)
              i_type = self.i_types.where(:itemtype_id => old_i_type.itemtype_id).last
            end

            if !i_type.blank?
              old_i_type.m_items.each do |old_m_item|
                m_item = i_type.m_items.where(:item_id => old_m_item.item_id).last
                if m_item.blank?
                  i_type.m_items << MItem.new(:item_id => old_m_item.item_id, :lad => old_m_item.lad, :rk => old_m_item.rk)
                else
                  m_item.rk = m_item.rk.to_i + old_m_item.rk.to_i
                  m_item.save!
                end
              end
            end
          end
          old_detail.destroy
        end
        self.save!
      end

      plannto_user_details = PUserDetail.where(:gid => self.google_user_id)
      if plannto_user_details.count > 1
        old_plannto_user_details = plannto_user_details.delete_if {|pud| pud.id == self.id }

        old_plannto_user_details.each do |old_detail|

          if self.pid.blank? && !old_detail.pid.blank?
            self.pid = old_detail.pid
          end

          old_detail.i_types.each do |old_i_type|
            valid_attributes = old_detail.attributes.slice("lid","mr", "g", "ai", "fr", "a")
            valid_attributes.delete_if {|k,v| v.blank?}
            self.update_attributes!(valid_attributes)

            i_type = self.i_types.where(:itemtype_id => old_i_type.itemtype_id).last
            if i_type.blank?
              self.i_types << IType.new(:itemtype_id => old_i_type.itemtype_id)
              i_type = self.i_types.where(:itemtype_id => old_i_type.itemtype_id).last
            end

            if !i_type.blank?
              old_i_type.m_items.each do |old_m_item|
                m_item = i_type.m_items.where(:item_id => old_m_item.item_id).last
                if m_item.blank?
                  i_type.m_items << MItem.new(:item_id => old_m_item.item_id, :lad => old_m_item.lad, :rk => old_m_item.rk)
                else
                  m_item.rk = m_item.rk.to_i + old_m_item.rk.to_i
                  m_item.save!
                end
              end
            end
          end
          old_detail.destroy
        end
        self.save!
      end

      if !self.gid.blank? && !self.pid.blank?
        $redis_rtb.pipelined do
          $redis_rtb.set("cm:#{self.gid}", self.pid)
          $redis_rtb.expire("cm:#{self.gid}", 1.weeks)
        end
      end
    # end
  end
end