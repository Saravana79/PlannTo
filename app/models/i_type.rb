class IType
  include Mongoid::Document
  # include Mongoid::Timestamps::Created

  # field :itemtype_id, type: Integer
  # field :list_of_urls, type: Array
  # field :click_item_ids, type: Array
  # field :lcd, type: Date #Last click date
  # field :order_item_ids, type: Array
  # field :lod, type: Date #Last order date
  # field :r, type: Boolean, :default => 0 #Resale
  # field :source, type: String

  field :itemtype_id, type: Integer
  field :lu, type: Array #list_of_urls
  field :ci_ids, type: Array  #click_item_ids
  field :lcd, type: Date #Last click date
  field :o_ids, type: Array #order_item_ids
  field :lod, type: Date #Last order date
  field :r, type: Boolean, :default => 0 #Resale
  field :source, type: Array
  field :fad, type: Date #first accessed date
  field :ssu, type: Array #source source url

  embedded_in :plannto_user_detail
  embeds_many :m_items
end