class RemoveStringFromUnwantedCharacter < ActiveRecord::Migration
  def up
    ArticleContent.where("url is not null").each do |article_content|
      unless article_content.url.nil?
        if article_content.title.include?("|")
          title = article_content.title.slice(0..(article_content.title.index('|'))).gsub(/\|/, "").strip
          article_content.update_attribute("title",title)
        end
        if article_content.title.include?("~")
          title = article_content.title.slice(0..(article_content.title.index('|'))).gsub(/\~/, "").strip
          article_content.update_attribute("title",title)
        end
      end     
    end
  end

  def down
  end
end

 
