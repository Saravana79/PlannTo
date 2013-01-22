class FollowsController < ApplicationController
  before_filter :authenticate_user!
  
  def destroy
    follow = Follow.find(params[:id])
    if  follow.followable_type  == "User"
        follow.remove_activity(current_user)
    end
    follow.destroy
    if params[:type] == "wizard"
       session[:wizard] = follow.follow_type
    end
    if params[:buying_plan_id]
      @buying_plan = BuyingPlan.find(params[:buying_plan_id])
      @follow_types = Itemtype.get_followable_types(@buying_plan.itemtype.itemtype)
      @itemtype = @buying_plan.itemtype
      @follow_item = Follow.for_follower(@buying_plan.user).where(:followable_type => @follow_types, :follow_type =>Follow::ProductFollowType::Buyer).group_by(&:followable_type)
   else
     redirect_to :back, :notice => "Successfully unfollowed."
   end  
  end
  
  def create
    follow = current_user.follows.where(followable_id: params[:follow][:followable_id]).where(followable_type: params[:follow][:followable_type]).first
    if follow.blank?
      current_user.follows.create(params[:follow])
      current_user.clear_user_follow_item
      if params[:follow][:followable_type]  == "User"
        UserActivity.save_user_activity(current_user, params[:follow][:followable_id],"followed","User",params[:follow][:followable_id],request.remote_ip)
      end 
  
      if params[:follow][:follow_type] == "buyer"
        @item = Item.find(params[:follow][:followable_id])
        @itemtype = Itemtype.find_by_itemtype(@item.itemtype.itemtype)
        @buying_plan = BuyingPlan.where(:user_id => current_user.id, :itemtype_id => @itemtype.id,:completed => false,:deleted => false).first
      if @buying_plan.nil?
        @buying_plan = BuyingPlan.create(:user_id => current_user.id, :itemtype_id => @itemtype.id)
        UserActivity.save_user_activity(current_user,@buying_plan.id,"added","Buying Plan",@buying_plan.id,request.remote_ip)
       #@buying_plan.update_attribute(:deleted, false)
       #@buying_plan.update_attribute(:completed, false) 
      end  
      if @question.nil?
       @question = UserQuestion.new(:title => "Planning to buy a #{@buying_plan.itemtype.itemtype}", :buying_plan_id => @buying_plan.id)
       @question.save
    end
   
  end

      if params[:follow][:type] == "wizard"
        session[:wizard] = params[:follow][:follow_type]
      end
   else
      current_user.follows.where(followable_id: params[:follow][:followable_id]).where(followable_type: params[:follow][:followable_type]).first.destroy
      current_user.follows.create(params[:follow])
      current_user.clear_user_follow_item
      if params[:follow][:followable_type]  == "User"
        UserActivity.save_user_activity(current_user, params[:follow][:followable_id],"followed","User",params[:follow][:followable_id],request.remote_ip)
      end 
      if params[:follow][:type] == "wizard"
        session[:wizard] = params[:follow][:follow_type]
      end  
    end
      
    redirect_to :back, :notice => "Successfully following."
  end
 end
