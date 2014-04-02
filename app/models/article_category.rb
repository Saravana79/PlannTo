class ArticleCategory < ActiveRecord::Base

  REVIEWS = "Reviews"
  TIPS = "Tips"
  QANDA = "Q&A"
  EVENT = "Event"
  APPS = "Apps"
  VIDEO = "Video"
  PHOTO = "Photo"
  ACCESSORIES = "Accessories"
  BOOKS = "Books"
  TRAVELOGUE = "Travelogue"
  MILES = "Miles"
  DEALS = "Deals"
  HOW_TO   = "HowTo/Guide"
  LIST = "Lists"
  COMPARISONS = "Comparisons"
  NEWS = "News"
  has_one :article_content
  belongs_to :itemtype
  validates_uniqueness_of :name, :scope => [:itemtype_id]

  #why zero is hardcoded here?
  #scope  :by_itemtype_id, lambda{|id| where(:itemtype_id => [0,id])}
  scope  :by_itemtype_id, lambda{|id| where(:itemtype_id => id).order_by_orderby}
  scope :order_by_orderby, order("orderby ASC")


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

  def self.get_by_itemtype(itemtype_id)
    keyword_id = "article_categories_#{itemtype_id}_lista"
    article_categories = $redis.zrange "#{keyword_id}", 0, -1
    if article_categories.size == 0
      article_categories = self.by_itemtype_id(itemtype_id)
      #save in cache
      $redis.multi do
        article_categories.each do |cont|
        logger.info cont.name
          $redis.zadd "#{keyword_id}", cont.orderby, "#{cont.id}_#{cont.name}"
        end
      end
      article_categories = $redis.zrange "#{keyword_id}", 0 ,-1

    end
    articles_list = Array.new
    article_categories.each do |category|
      sub_cat = category.split("_")
      articles_list << [sub_cat[1], sub_cat[0]]
    end
    return articles_list
  end
end
