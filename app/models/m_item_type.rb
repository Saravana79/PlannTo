class MItemType
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  field :itemtype_id, type: Integer
  field :list_of_urls, type: Array
  field :click_item_ids, type: Array
  field :last_click_date, type: Date

  embedded_in :plannto_user_detail
  embeds_many :m_items
end