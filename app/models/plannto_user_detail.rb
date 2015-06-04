class PlanntoUserDetail
  include Mongoid::Document
  # include Mongoid::Timestamps::Created
  after_save :update_last_accessed_date, :update_duplicate_record

  attr_accessor :skip_callback, :skip_duplicate_update


  field :plannto_user_id, type: String
  field :gender, type: String  #value M/F
  field :google_user_id, type: String
  field :lad, type: Date #Last acessed date
  field :m_rank, type: Integer #Male Ranking
  field :f_rank, type: Integer #Female Ranking
  field :a, type: String # Additional detail

  embeds_many :m_item_types
  # embeds_many :m_items

  index({ plannto_user_id: 1 })
  index({ google_user_id: 1 })

  def self.update_plannto_user_detail(impression)
    # plannto user details
    if !impression.temp_user_id.blank?
      plannto_user_detail = PlanntoUserDetail.where(:plannto_user_id => impression.temp_user_id).first

      if (!plannto_user_detail.blank? && plannto_user_detail.google_user_id.blank?)
        cookie_match = CookieMatch.where(:plannto_user_id => impression.temp_user_id).last
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          plannto_user_detail.google_user_id = cookie_match.google_user_id
          plannto_user_detail.save!
        end
      elsif plannto_user_detail.blank?
        plannto_user_detail = PlanntoUserDetail.new(:plannto_user_id => impression.temp_user_id)
        cookie_match = CookieMatch.where(:plannto_user_id => impression.temp_user_id).last
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          plannto_user_detail.google_user_id = cookie_match.google_user_id
        end
        plannto_user_detail.save!
      end
    end

    if !plannto_user_detail.blank?
      itemtype_id = nil
      #plannto user details
      if !impression.item_id.blank?
        itemtype = Item.where(:id => impression.item_id).select(:itemtype_id).first
        itemtype_id = itemtype.itemtype_id rescue ""
      end

      if !itemtype_id.blank?
        m_item_type = plannto_user_detail.m_item_types.where(:itemtype_id => itemtype_id).last
        if m_item_type.blank?
          plannto_user_detail.m_item_types << MItemType.new(:itemtype_id => itemtype_id)
          m_item_type = plannto_user_detail.m_item_types.where(:itemtype_id => itemtype_id).last
        end

        item_id = impression.item_id

        m_item = m_item_type.m_items.where(:item_id => item_id).last

        if m_item.blank?
          lad = Date.today
          ranking = 30
          m_item_type.m_items << MItem.new(:item_id => item_id, :lad => lad, :ranking => ranking)
        else
          m_item.lad = Date.today
          m_item.ranking = m_item.ranking.to_i + 30
          m_item.save!
        end

        order_item_ids = m_item_type.order_item_ids
        order_item_ids = order_item_ids.blank? ? [impression.item_id.to_i] : (order_item_ids + [impression.item_id.to_i])
        order_item_ids = order_item_ids.map(&:to_i).compact.uniq
        m_item_type.order_item_ids = order_item_ids
        m_item_type.lod = Date.today
        m_item_type.save!
      end

      plannto_user_detail.save!
    end
  end

  def update_additional_details(url)
    domain = Item.get_host_without_www(url)
    redis_rtb = {}
    male_site_list = ["team-bhp.com", "gadgetstouse.com"]
    female_site_list = ["makeupandbeauty.com", "stylecraze.com", "bollywoodshaadis.com", "southindiafashion.com", "wiseshe.com", "indusladies.com", "celebritysaree.com"]
    resale_site_list = ["olx.in", "quikr.com", "classifieds.team-bhp.com"]
    buying_cycle_site_list = ["mysmartprices.com", "smartprix.com", "pricebaba.com"]

    user_id_for_key = ""
    if self.plannto_user_id.blank?
      user_id_for_key = self.google_user_id.to_s
      key_prefix = "ubl:#{user_id_for_key}"
    else
      user_id_for_key = self.plannto_user_id.to_s
      key_prefix = "ubl:pl:#{user_id_for_key}"
    end

    if male_site_list.include?(domain)
      self.m_rank = self.m_rank.to_i + 1
    elsif female_site_list.include?(domain)
      self.f_rank = self.f_rank.to_i + 1
    elsif resale_site_list.include?(domain)
      a_hash = self.a.to_s.split("<<").map {|each_v| each_v.split(",")}
      a_hash = Hash[a_hash]
      a_hash.merge!("resale" => "true", "rad" => Date.today.to_s) #rad => resale last accessed date
      self.a = a_hash
      redis_rtb.merge!("#{key_prefix}:ad:rs" => Date.today.to_s) if !key_prefix.blank?
    elsif buying_cycle_site_list.include?(domain)
      a_hash = self.a.to_s.split("<<").map {|each_v| each_v.split(",")}
      a_hash = Hash[a_hash]
      a_hash.merge!("bc" => "true", "bcad" => Date.today.to_s) #bcad => buying cycle last accessed date
      self.a = a_hash
      redis_rtb.merge!("#{key_prefix}:ad:bc" => Date.today.to_s) if !key_prefix.blank?
    end

    if self.m_rank.to_i > self.f_rank.to_i
      self.gender = "m"
      redis_rtb.merge!("#{key_prefix}:g" => "male") if !key_prefix.blank?
    elsif self.m_rank.to_i < self.f_rank.to_i
      self.gender = "f"
      redis_rtb.merge!("#{key_prefix}:g" => "female") if !key_prefix.blank?
    end

    self.skip_callback = true
    self.skip_duplicate_update = true

    self.save!

    return redis_rtb
  end

  private

  def update_last_accessed_date
    if self.skip_callback != true
      self.skip_callback = true
      self.lad = Date.today
      self.save
    end
  end

  def update_duplicate_record
    if self.skip_duplicate_update != true

      if self.plannto_user_id_changed?
        self.skip_duplicate_update = true
        plannto_user_details = PlanntoUserDetail.where(:plannto_user_id => self.plannto_user_id)
        p plannto_user_details.count
        if plannto_user_details.count > 1
          old_plannto_user_details = plannto_user_details.delete_if {|pud| pud.id == self.id }

          old_plannto_user_details.each do |old_detail|
            self.skip_duplicate_update = true

            if self.google_user_id.blank? && !old_detail.google_user_id.blank?
              self.google_user_id = old_detail.google_user_id
            end

            old_detail.m_item_types.each do |old_m_item_type|
              m_item_type = self.m_item_types.where(:itemtype_id => old_m_item_type.itemtype_id).last
              if m_item_type.blank?
                self.m_item_types << MItemType.new(:itemtype_id => old_m_item_type.itemtype_id)
                m_item_type = self.m_item_types.where(:itemtype_id => old_m_item_type.itemtype_id).last
              end

              if !m_item_type.blank?
                old_m_item_type.m_items.each do |old_m_item|
                  m_item = m_item_type.m_items.where(:item_id => old_m_item.item_id).last
                  if m_item.blank?
                    m_item_type.m_items << MItem.new(:item_id => old_m_item.item_id, :lad => old_m_item.lad, :ranking => old_m_item.ranking)
                  else
                    m_item.ranking = m_item.ranking.to_i + old_m_item.ranking.to_i
                    m_item.save!
                  end
                end
              end
            end
            old_detail.destroy
          end
          self.save!
        end

        if !self.google_user_id.blank? && !self.plannto_user_id.blank?
          $redis_rtb.pipelined do
            $redis_rtb.set("cm:#{self.google_user_id}", self.plannto_user_id)
            $redis_rtb.expire("cm:#{self.google_user_id}", 2.weeks)
          end
        end
      elsif self.google_user_id_changed?
        self.skip_duplicate_update = true
        plannto_user_details = PlanntoUserDetail.where(:google_user_id => self.google_user_id)
        if plannto_user_details.count > 1
          old_plannto_user_details = plannto_user_details.delete_if {|pud| pud.id == self.id }

          old_plannto_user_details.each do |old_detail|

            if self.plannto_user_id.blank? && !old_detail.plannto_user_id.blank?
              self.plannto_user_id = old_detail.plannto_user_id
            end

            old_detail.m_item_types.each do |old_m_item_type|
              m_item_type = self.m_item_types.where(:itemtype_id => old_m_item_type.itemtype_id).last
              if m_item_type.blank?
                self.m_item_types << MItemType.new(:itemtype_id => old_m_item_type.itemtype_id)
                m_item_type = self.m_item_types.where(:itemtype_id => old_m_item_type.itemtype_id).last
              end

              if !m_item_type.blank?
                old_m_item_type.m_items.each do |old_m_item|
                  m_item = m_item_type.m_items.where(:item_id => old_m_item.item_id).last
                  if m_item.blank?
                    m_item_type.m_items << MItem.new(:item_id => old_m_item.item_id, :lad => old_m_item.lad, :ranking => old_m_item.ranking)
                  else
                    m_item.ranking = m_item.ranking.to_i + old_m_item.ranking.to_i
                    m_item.save!
                  end
                end
              end
            end
            old_detail.destroy
          end
          self.save!
        end

        if !self.google_user_id.blank? && !self.plannto_user_id.blank?
          $redis_rtb.pipelined do
            $redis_rtb.set("cm:#{self.google_user_id}", self.plannto_user_id)
            $redis_rtb.expire("cm:#{self.google_user_id}", 2.weeks)
          end
        end

      end
    end
  end
end