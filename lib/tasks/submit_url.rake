desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil?
      extname = File.extname(article.url).delete("%")
      basename = File.basename(article.url, extname).delete("%")
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(article.url)) do |data|  
        file.write data.read
      end
      file.rewind
      if article.content_photo.nil?
         p = ContentPhoto.create(:photo => file,:url => article.url,:content_id => article.id)
         article.update_attribute('thumbnail',article.content_photo.photo.url) 
     end   
   end 
 end  
end
