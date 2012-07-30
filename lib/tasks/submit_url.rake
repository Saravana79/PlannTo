desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil?
      photo = article.content_photo
      extname = File.extname(article.url)
      basename = File.basename(article.url, extname)
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(article.url)) do |data|  
        file.write data.read
      end
      file.rewind
      photo.photo = file
      photo.content_id = article.id
      photo.save
      article.update_attribute('thumbnail',article.content_photo.photo.url)
   end 
 end  
end
