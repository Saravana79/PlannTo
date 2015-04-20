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

  private

  def update_last_accessed_date
    if self.skip_callback != true
      self.skip_callback = true
      self.last_accessed_date = Date.today
      self.save
    end
  end
end