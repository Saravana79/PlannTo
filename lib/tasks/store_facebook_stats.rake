desc "save facebook share content i.e to local db"
  task :get_facebook_stats, [:start_id, :needs] => :environment do | t, args|
     ArticleContent.where("url is not null and id > ?",args[:start_id]).each do |url|
        puts "#{url.url} has not been proccessed will update next time" unless url.update_facebook_stats
     end
 end
 

