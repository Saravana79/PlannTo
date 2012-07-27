namespace :plannto do

  desc "load article categories"

  task :load_article_categories => :environment do
    ArticleCategory.delete_all

    itemtype = Itemtype.where(:itemtype => "Car").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Travelogue", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Mobile").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Apps", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Camera").first

    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Books", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

    itemtype = Itemtype.where(:itemtype => "Tablet").first
    ArticleCategory.create(:name => "Reviews", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Tips", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Apps", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Video", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Photo", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "News", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Deals", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "Event", :itemtype_id => itemtype.id)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => itemtype.id)

  end

  desc "load bookmark article categories"

  task :load_bookmark_article_categories => :environment do
    ArticleCategory.create(:name => "Reviews", :itemtype_id => 0)
    ArticleCategory.create(:name => "Q&A", :itemtype_id => 0)
    ArticleCategory.create(:name => "Tips", :itemtype_id => 0)
    ArticleCategory.create(:name => "Accessories", :itemtype_id => 0)
    ArticleCategory.create(:name => "Apps", :itemtype_id => 0)
    ArticleCategory.create(:name => "Video", :itemtype_id => 0)
    ArticleCategory.create(:name => "Photo", :itemtype_id => 0)
    ArticleCategory.create(:name => "News", :itemtype_id => 0)
    ArticleCategory.create(:name => "Deals", :itemtype_id => 0)
    ArticleCategory.create(:name => "Event", :itemtype_id => 0)
    ArticleCategory.create(:name => "HowTo/Guide", :itemtype_id => 0)
    ArticleCategory.create(:name => "Travelogue", :itemtype_id => 0)
    ArticleCategory.create(:name => "Apps", :itemtype_id => 0)
    ArticleCategory.create(:name => "Books", :itemtype_id => 0)
  end

  desc "load content itemtype relations"

  task :load_content_itemtype_relations => :environment do
  ContentItemtypeRelation.destroy_all
    contents = Content.all
    contents.each do |content|
      item_ids = ContentItemRelation.where(:content_id => content.id).collect(&:item_id)
      itemtype_ids = Array.new
      item_ids.each do |item_id|
        item = Item.find(item_id)
        itemtype_ids << content.get_itemtype(item)
      end
      itemtype_ids.uniq.each do |itemtype_id|
        ContentItemtypeRelation.create(:itemtype_id => itemtype_id, :content_id => content.id)
      end
    end

  end

end
