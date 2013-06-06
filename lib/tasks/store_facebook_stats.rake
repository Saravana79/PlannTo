desc "save facebook share content i.e to local db"
  task :get_facebook_stats => :environment do
     ArticleContent.where("url is not null").each do |url|
        puts "#{url.url} has not been proccessed will update next time" unless url.update_facebook_stats
     end
 end
 

