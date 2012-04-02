module SharesHelper

  def find_article_category(article_categories, category)  
    cat = article_categories.find {|s| s[0] == category.to_s}  
    return cat[1]  unless cat.nil?
    return "0"

  end
end
