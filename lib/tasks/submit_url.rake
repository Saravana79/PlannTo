desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil?
      photo = article.content_photo
      photo.photo= URI.parse(article.url)
      photo.content_id = article.id
      photo.save
      article.update_attribute('thumbnail',article.content_photo.photo.url)
   end 
 end  
end
