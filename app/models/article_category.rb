class ArticleCategory < ActiveRecord::Base

  REVIEWS = "Reviews"
  TIPS = "Tips"
  QANDA = "Q&A"
  EVENT = "Event"
  APPS = "Apps"
  ACCESSORIES = "Accessories"
  BOOKS = "Books"
  TRAVELOGUE = "Travelogue"
  has_one :article_content
  belongs_to :itemtype
  validates_uniqueness_of :name, :scope => [:itemtype_id]

  #why zero is hardcoded here?
  #scope  :by_itemtype_id, lambda{|id| where(:itemtype_id => [0,id])}
  scope  :by_itemtype_id, lambda{|id| where(:itemtype_id => id)}

  def is_event?
    self.name == EVENT
  end

  def is_app?
    self.name == APPS
  end

  def is_books?
    self.name == BOOKS
  end

  def is_accessories?
    self.name == ACCESSORIES
  end
end
