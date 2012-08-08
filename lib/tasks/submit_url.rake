desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil? and article.thumbnail.nil?
      extname = File.extname(article.thumbnail).delete("%")
      basename = File.basename(article.thumbnail, extname).delete("%")
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(article.thumbnail)) do |data|  
        file.write data.read
      end
      file.rewind
      p = ContentPhoto.create(:photo => file,:content_id => article.id)
      cp = ContentPhoto.find_by_content_id(article.id)
      article.update_attribute('thumbnail',cp.photo.url(:thumb)) 
     end 
   end  
 end
