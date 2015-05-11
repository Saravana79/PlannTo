class PlanntoUserDetail
  include Mongoid::Document
  # include Mongoid::Timestamps::Created
  after_save :update_last_accessed_date

  attr_accessor :skip_callback


  field :plannto_user_id, type: String
  field :gender, type: String
  field :google_user_id, type: String
  field :last_accessed_date, type: Date

  embeds_many :m_item_types
  # embeds_many :m_items

  index({ plannto_user_id: 1, google_user_id: 1 })

  def self.update_plannto_user_detail(impression)
    # plannto user details
    if !impression.temp_user_id.blank?
      plannto_user_detail = PlanntoUserDetail.where(:plannto_user_id => impression.temp_user_id).first

      if plannto_user_detail.blank?
        cookie_match = CookieMatch.where(:plannto_user_id => impression.temp_user_id).select(:google_user_id).last
        if !cookie_match.blank? && !cookie_match.google_user_id.blank?
          plannto_user_detail = PlanntoUserDetail.new(:plannto_user_id => impression.temp_user_id)
          plannto_user_detail.google_user_id = cookie_match.google_user_id
          plannto_user_detail.save!
        end
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
        m_item_type.last_order_date = Date.today
        m_item_type.save!
      end

      plannto_user_detail.save!
    end
  end

  private

  def update_last_accessed_date
    if self.skip_callback != true
      self.skip_callback = true
      self.last_accessed_date = Date.today
      self.save
    end
  end
end