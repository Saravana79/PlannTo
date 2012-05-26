class AccountsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_user_info
  def index

  end

  def update
    avatar_attributes = params[:user][:avatar]
    current_user.update_attributes(params[:user].delete_if{|key, value| key ==:avatar})
    if current_user.errors.blank?
      $redis.hdel("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{current_user.id}", "avatar_url")
      $redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{current_user.id}", "name", current_user.name)
      if avatar_attributes
        avatar_attributes[:user_id] = current_user.id
        Avatar.find_or_create_by_user_id(current_user.id) && current_user.avatar.update_attributes(avatar_attributes)
        flash[:notice] = "Account update successfully"
      else
        flash[:notice] = "please upload the avatar from profile page"
      end
    else
      flash[:notice] = current_user.errors.full_messages.join(", ")
    end
    redirect_to :action => :index
  end

  def change_password
    if @user.update_with_password(params[:user])
       sign_in(@user, :bypass => true)
       flash[:notice] =  "Password successfully update"
    else
      flash[:notice] = @user.errors.full_messages.join(", ")
    end
  end

  def get_user_info
    @user = current_user
    @facebook_user = facebook_profile
  end

  def profile
    require 'will_paginate/array'

    @follow_types = Itemtype.get_followable_types(params[:follow])
    @follow_item = Follow.for_follower(current_user).where(:followable_type => @follow_types).group_by(&:followable_type)
    respond_to do|format|      
      format.html {render :layout => "product"}
    end
  end

  def buying_plans
    @buying_plans = BuyingPlan.where("user_id = ?", current_user.id)
  end
  
end
