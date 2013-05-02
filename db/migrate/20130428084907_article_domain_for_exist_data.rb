class ArticleDomainForExistData < ActiveRecord::Migration
  def up
     ArticleContent.where('url is not null and id > 11000').each do |article|
       url = "http://#{article.url}" if URI.parse(article.url).scheme.nil?
       host = URI.parse(article.url).host.downcase rescue ""
       article.update_attribute('domain',(host.start_with?('www.') ? host[4..-1] : host rescue ""))
      
      end
  end

  def down
  end
end
