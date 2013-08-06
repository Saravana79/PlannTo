class BuyingPlan < ActiveRecord::Base
  include Extensions::UUID

  has_one :user_question, :dependent => :destroy
  belongs_to :user
  belongs_to :itemtype
  has_many :preferences
  has_one :proposal
  def preference_page_url
    return "/preferences/#{self.itemtype.itemtype.downcase}/#{self.uuid}"
  end
  def self.finding_buyng_plan(user,itemtype ,remote_ip)
    itemtype = Itemtype.find_by_itemtype(itemtype)
    if !user 
      buying_plan = BuyingPlan.where(:temporary_buying_plan_ip => remote_ip,:user_id => 0, :itemtype_id => itemtype.id,:completed => false,:deleted => false).first
    return buying_plan 
   else 
     buying_plan = BuyingPlan.where(:user_id => user.id, :itemtype_id =>          itemtype.id,:completed => false,:deleted => false).first
    return buying_plan 
    end
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
       buying_plans =  BuyingPlan.where('itemtype_id =? and user_id =? and completed =? ', b.itemtype.id,user.id,false).all
       b.update_attributes(:user_id=>user.id,:temporary_buying_plan_ip => "")
       UserActivity.save_user_activity(user,b.id,"added","Buying Plan",b.id,ip)
       if !buying_plans.nil?
         buying_plans.each do |buying_plan|
           @follow_types = Itemtype.get_followable_types(buying_plan.itemtype.itemtype)
           @follow_item = Follow.for_follower(user).where(:followable_type => @follow_types,:follow_type =>Follow::ProductFollowType::Buyer)
           item_ids = @follow_item.collect(&:followable_id).join(',')
           buying_plan.update_attributes(:completed => true)
           buying_plan.update_attribute('items_considered',item_ids)
           @follow_item.each do |item|
             item.destroy
           end 
         end   
       end 
       Item.where("id in (?)",b.items_considered.to_s.split(",")).each do |i|
         Follow.wizard_save(i.id.to_s, "buyer",user)
         user.clear_user_follow_item
       end
       b.update_attribute('items_considered',"")  
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
    UserActivity.where("related_activity_type =? and related_id in (?)","Buying Plan-Recommend",self.user_question.user_answers.collect(&:id)).each do|ac|
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
