class RemoveUnwantedStringFromUrl < ActiveRecord::Migration
  def up
    ArticleContent.where("url is not null").each do |article_content|
      unless article_content.url.nil?
        if article_content.url.include?("?utm_source=feedburner")
          url = article_content.url.split("?")[0]
          article_content.update_attribute("url",url)
        end
      end     
    end
  end

  def down
  end
end
