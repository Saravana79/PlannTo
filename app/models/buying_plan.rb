class BuyingPlan < ActiveRecord::Base
  include Extensions::UUID

  has_one :user_question, :dependent => :destroy
  belongs_to :user
  belongs_to :itemtype
  has_many :preferences
  
  def preference_page_url
    return "/preferences/#{self.itemtype.itemtype.downcase}/#{self.uuid}"
  end
  
  def get_first_item
    Item.find(Follow.for_follower(self.user).where(:followable_type =>  self.itemtype.itemtype, :follow_type =>Follow::ProductFollowType::Buyer).first.followable_id) rescue "" 
 end
  
  def self.owned_item(itemtype,user)
   item_ids =  Follow.where('follower_id =? and follow_type =? and followable_type=?',user.id,"owner",itemtype).collect(&:followable_id)
   @items = Item.where("id in(?)",item_ids.last)
  end
  
  def self.recommended_items(answers)
    @items = []
    answers.each do |ans|
      ans.recommendations.each  do |reco|
      
        @items << reco.item
    end
    end
    return @items
  end 
  
  def  remove_user_activities
    UserActivity.where("related_activity_type =? and related_id =?","Buying Plan",self.id).each do|ac|
     ac.destroy
    end 
  end
     
  def content_vote_count
    count = $redis.get("#{VoteCount::REDIS_BUYING_PLAN_VOTE_KEY_PREFIX}#{self.id}")
    if count.nil?
      vote = VoteCount.search_vote(self).first
      count = vote.nil? ? 0 : (vote.vote_count_positive - vote.vote_count_negative)
      $redis.set("#{VoteCount::REDIS_BUYING_PLAN_VOTE_KEY_PREFIX}#{self.id}", count)
      return count
    else
      return count
    end
  end
end
