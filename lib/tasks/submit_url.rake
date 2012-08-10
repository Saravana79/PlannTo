desc "save url content to local"
task :submit_url, [:argument] => :environment do
puts "save content to local by url ***"
  ArticleContent.all.each do |article|
    unless article.url.nil? and article.thumbnail.nil?
      puts article.id
      safe_thumbnail_url = URI.encode(article.thumbnail, "[],{},()")
      extname = File.extname(safe_thumbnail_url).delete("%")
      basename = File.basename(safe_thumbnail_url, extname).delete("%")
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(safe_thumbnail_url)) do |data|  
        file.write data.read
      end
      puts "1"
      file.rewind
      if article.content_photo.nil?
        p = ContentPhoto.create(:photo => file,:url => article.thumbnail.to_s,:content_id => article.id)
        puts "2"
        cp = ContentPhoto.find_by_content_id(article.id)
        puts "3"
        article.update_attribute('thumbnail',cp.photo.url(:thumb).to_s) 
        puts "4"
      end  
     end 
   end  
 end
 

