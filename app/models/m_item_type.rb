class MItemType
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :itemtype_id, type: Integer
  field :list_of_urls, type: Array
  field :click_item_ids, type: Array
  field :lcd, type: Date #Last click date
  field :order_item_ids, type: Array
  field :lod, type: Date #Last order date

  embedded_in :plannto_user_detail
  embeds_many :m_items
end