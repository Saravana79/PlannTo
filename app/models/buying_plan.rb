class BuyingPlan < ActiveRecord::Base
  include Extensions::UUID

  has_one :user_question, :dependent => :destroy
  belongs_to :user
  belongs_to :itemtype
  has_many :preferences
  
  def preference_page_url
    return "/preferences/#{self.itemtype.itemtype.downcase}/#{self.uuid}"
  end
  
  def self.buying_plan_move_from_without_login(user,ip)
    BuyingPlan.where(:temporary_buying_plan_ip => ip).each do |b|
      b.update_attributes(:user_id=>user.id,:temporary_buying_plan_ip => "")
      Item.where("id in (?)",b.items_considered.to_s.split(",")).each do |i|
        Follow.wizard_save(i.id.to_s, "buyer",user)
        user.clear_user_follow_item
      end
       UserActivity.save_user_activity(user,b.id,"added","Buying Plan",b.id,ip)
       b.update_attribute('items_considered',"")   
    end   
  end
 
  def self.buying_plan_move_from_without_login_for_has_account(user,ip)
    BuyingPlan.where(:temporary_buying_plan_ip => ip).each do |b|
      buying_plan = BuyingPlan.where('itemtype_id =? and user_id =?', b.itemtype.id,user.id).first
      if buying_plan.nil?
        b.update_attributes(:user_id=>user.id,:temporary_buying_plan_ip => "")
        Item.where("id in (?)",b.items_considered.to_s.split(",")).each do |i|
          Follow.wizard_save(i.id.to_s, "buyer",user)
          user.clear_user_follow_item
        end
        UserActivity.save_user_activity(user,b.id,"added","Buying Plan",b.id,ip)
        b.update_attribute('items_considered',"") 
     else
        b.update_attribute('temporary_buying_plan_ip',"")
        buying_plan.update_attributes(:user_id=>user.id,:temporary_buying_plan_ip => "")
        buying_plan.update_attribute(:deleted, false)
        buying_plan.update_attribute(:completed, false)
        Item.where("id in (?)",b.items_considered.to_s.split(",")).each do |i|
          Follow.wizard_save(i.id.to_s, "buyer",user)
          user.clear_user_follow_item
        end
        UserActivity.save_user_activity(user,b.id,"added","Buying Plan",b.id,ip)
        b.update_attribute('items_considered',"")         
      end  
    end
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
