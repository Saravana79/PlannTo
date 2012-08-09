desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil? and article.thumbnail.nil?
      safe_thumbnail_url = URI.encode(article.thumbnail, "[],{},()")
      extname = File.extname(safe_thumbnail_url).delete("%")
      basename = File.basename(safe_thumbnail_url, extname).delete("%")
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(safe_thumbnail_url)) do |data|  
        file.write data.read
      end
      file.rewind
      if article.content_photo.nil?
        p = ContentPhoto.create(:photo => file,:url => article.url,:content_id => article.id)
        cp = ContentPhoto.find_by_content_id(article.id)
        article.update_attribute('thumbnail',cp.photo.url(:thumb)) 
      end  
     end 
   end  
 end
 

