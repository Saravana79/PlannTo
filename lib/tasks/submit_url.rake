desc "save url content to local"
  task :submit_url,:arg1, :needs => :environment do | t, args|
    #ItemContentsRelationsCache.delete_all
    puts args[:arg1]
    arg1 = args[:arg1]
    puts "save content to local by url ***"
    articles = ArticleContent.find(:all, :conditions=>["id > ?" , arg1])
    articles.each do |article|
    unless article.url.nil? or article.thumbnail.nil? or article.thumbnail == ""
      puts article.id
      safe_thumbnail_url = URI.encode(article.thumbnail)
      extname = File.extname(safe_thumbnail_url).delete("%")
      basename = File.basename(safe_thumbnail_url, extname).delete("%")
      file = Tempfile.new([basename, extname])
      file.binmode
      open(URI.parse(safe_thumbnail_url)) do |data|  
        file.write data.read
      end
      file.rewind
      if article.content_photo.nil?
        p = ContentPhoto.create(:photo => file,:url => article.thumbnail.to_s,:content_id => article.id)
        cp = ContentPhoto.find_by_content_id(article.id)
        article.update_attribute('thumbnail',cp.photo.url(:thumb).to_s)         
      end  
     end 
   end  
 end
 

