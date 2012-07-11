module FollowMethods
  def follow_item_type
    @related_items = params[:related_items] == "true"    
    case params[:follow_type]
      when 'buyer'
        plan_to_buy_item
      when 'owner'
        own_a_item
      when 'follower'
        follow_this_item
    end
    respond_to do |format|
      unless params[:unfollow]
        format.js { render :template => 'items/plan_to_buy_item', :button_class => params[:button_class]}
      else
        format.js { render :template => 'items/plan_to_buy_item_unfollow', :button_class => params[:button_class]}
      end
      format.html{
        after_ajax_call_path_for
      }
    end
  end

  def plan_to_buy_item
    @type = "buy"
    follow = follow_item(params[:follow_type], params[:unfollow])
    current_user.clear_user_follow_item
    #if follow.blank?
    #  flash[:notice] = "You already buy this Item"
    #else
    #  flash[:notice] = "Planning is saved"
    #end

  end

  def own_a_item
    @type = "own"
    follow = follow_item(params[:follow_type], params[:unfollow])
    current_user.clear_user_follow_item
  #  if follow.blank?
  #    flash[:notice] = "You are already owning this Item"
  #  else
  #    flash[:notice] = "Owner is saved"
  #  end

  end

  def follow_this_item
    @type = "follow"
    follow = follow_item(params[:follow_type], params[:unfollow])
    current_user.clear_user_follow_item
 #   if follow.blank?
 #     flash[:notice] = "You are already Following this Item"
 #   else
 #     flash[:notice] = "Follow is saved"
 #   end

  end

  private

  def follow_item(follow_type, unfollow= false)
    Rails.cache.delete("item_follow_"+current_user.id.to_s)    
    if !@item.blank?
      if unfollow
        current_user.stop_following(@item)
      else
        current_user.follow(@item, follow_type)
      end
    else
      false
    end

  end
end
