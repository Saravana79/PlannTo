namespace :plannto do
 
  desc "load article categories"
   
  task :load_article_categories => :environment do
    #ArticleCategory.delete_all

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
    ArticleCategory.create(:name => "HowTo/KB", :itemtype_id => itemtype.id)

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
    ArticleCategory.create(:name => "HowTo/KB", :itemtype_id => itemtype.id)

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
    ArticleCategory.create(:name => "HowTo/KB", :itemtype_id => itemtype.id)

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
    ArticleCategory.create(:name => "HowTo/KB", :itemtype_id => itemtype.id)

  
  end


end
