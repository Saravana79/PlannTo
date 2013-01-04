class AddExistPlanToBuyItemsToBuyingPlans < ActiveRecord::Migration
  def change
 
      Follow.where(:follow_type => "buyer").each do |follow| 
      @itemtype = Itemtype.find_by_itemtype(follow.followable_type.downcase)
      @buying_plan = BuyingPlan.where(:user_id => follow.follower_id, :itemtype_id => @itemtype.id).first
       if @buying_plan.nil?
        @buying_plan = BuyingPlan.create(:user_id => follow.follower_id, :itemtype_id => @itemtype.id)
        activity = UserActivity.new
        activity.user_id = follow.follower_id
        activity.related_id = @buying_plan.id
        activity.related_activity = "added"
        activity.related_activity_type = "Buying Plan"
        activity.time = follow.created_at
        activity.activity_id = @buying_plan.id
        activity.save
        @buying_plan.update_attribute(:deleted, false)
        @buying_plan.update_attribute(:completed, false)
      end  
     
      @question = @buying_plan.user_question #.destroy
    if @question.nil?
      @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
      @question.save
    end
    end
   
  end
  
end
