class ArticleCategory < ActiveRecord::Base

  REVIEWS = "Reviews"
  TIPS = "Tips"
  QANDA = "Q&A"
  EVENT = "Event"
  has_one :article_content
  belongs_to :itemtype
  validates_uniqueness_of :name, :scope => [:itemtype_id]
  
  scope  :by_itemtype_id, lambda{|id| where(:itemtype_id => [0,id])}
end
