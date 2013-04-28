class UpdateItemRatings < ActiveRecord::Migration
  def change
     drop_table :item_ratings
     create_table :item_ratings, :force => true do |t|
      t.decimal  :expert_review_avg_rating , :precision => 8, :scale => 2
      t.integer  :expert_review_count
      t.integer  :expert_review_total_count
      t.decimal  :user_review_avg_rating, :precision => 8, :scale => 2
      t.integer  :user_review_count
      t.integer  :user_review_total_count
      t.decimal  :average_rating, :precision => 8, :scale => 2
      t.integer  :review_count
      t.integer  :review_total_count
      t.integer  :item_id 
      t.timestamps
    end  
    Item.all.each do |item|  
        created_reviews = Array.new
        complete_created_reviews = item.contents.where(:type => 'ReviewContent' )    
        complete_created_reviews.each do |rev|
           created_reviews << rev unless (rev.rating.to_i == 0 || rev.rating.nil?)
     end
      shared_reviews = Array.new
      complete_shared_reviews = item.contents.where("sub_type = '#{ArticleCategory::REVIEWS}' and type != 'ReviewContent'" )   
      complete_shared_reviews.each do |rev|   
      shared_reviews << rev unless (rev.field1.to_i == 0 || rev.field1.nil?)
    end
      #return 0 if (created_reviews.empty? && shared_reviews.empty?)
      unless created_reviews.empty?
      created_avg_sum = created_reviews.inject(0){|sum,review| sum += review.rating} 
    else
        created_avg_sum = 0
    end
    unless shared_reviews.empty?
    shared_avg_sum = shared_reviews.inject(0){|sum,review| sum += review.field1.to_i}
    else
      shared_avg_sum = 0
    end
    if(created_avg_sum == 0 && shared_avg_sum == 0)
    
      item_rating =  0
    
    else
      rating = (created_avg_sum + shared_avg_sum)/(created_reviews.size.to_f + shared_reviews.size.to_f) rescue 0.0
     
    end  
       if (created_avg_sum == 0 && shared_avg_sum == 0) || shared_reviews.size == 0 || created_reviews.size == 0
          expert_review_avg_rating = 0
         user_review_avg_rating = 0 
      else
         expert_review_avg_rating = (shared_avg_sum)/(shared_reviews.size).to_f rescue 0.0
     user_review_avg_rating = (created_avg_sum)/(created_reviews.size).to_f rescue 0.0   end    
    
     user_review_count = created_reviews.size
     expert_review_count = shared_reviews.size
     expert_review_total_count = complete_shared_reviews.size        
     user_review_total_count = complete_created_reviews.size
   
     average_rating = rating
     review_count =  user_review_count + expert_review_count
     review_total_count =   user_review_total_count   +      expert_review_total_count
      
       item_rating1 = ItemRating.new
         item_rating1.user_review_count = user_review_count
         item_rating1.expert_review_count = expert_review_count
         item_rating1.expert_review_total_count = expert_review_total_count      
         item_rating1.user_review_total_count = complete_created_reviews.size
         item_rating1.expert_review_avg_rating =  expert_review_avg_rating
         item_rating1.user_review_avg_rating = user_review_avg_rating
         item_rating1.average_rating = average_rating 
         item_rating1.review_count =  user_review_count + expert_review_count
         item_rating1.review_total_count =     review_total_count
         item_rating1.item_id = item.id
         item_rating1.save
        end
  end
end
