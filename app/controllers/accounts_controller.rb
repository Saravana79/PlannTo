class AccountsController < ApplicationController
  layout "product"
  before_filter :authenticate_user!
  before_filter :get_user_info
  def index
    @type = params[:type]
  end

  def update
    #avatar_attributes = params[:user][:avatar]
    #user_attribute = params[:user].delete("avatar")
    #current_user.update_attributes(user_attribute)
    #if current_user.errors.blank?
      #$redis.hdel("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{current_user.id}", "avatar_url")
      #$redis.hset("#{User::REDIS_USER_DETAIL_KEY_PREFIX}#{current_user.id}", "name", current_user.name)
      #if avatar_attributes
        #avatar_attributes[:user_id] = current_user.id
        #Avatar.find_or_create_by_user_id(current_user.id) && current_user.avatar.update_attributes(avatar_attributes)
        #flash[:notice] = "Account update successfully"
      #else
        #flash[:notice] = "please upload the avatar from profile page"
      #end
    if current_user.update_attributes(params[:user])  
      flash[:notice] = "Account update successfully"
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
    if(!params[:follow])
      params[:follow] = 'Products'
    end
    @user = User.find(:first, :conditions => ["username like ?","#{params[:username]}"])
     if params[:follow] == "Followers" || params[:follow] == "Following"
      @follows,@users = Follow.get_followers_following(@user,params[:follow],params[:page],8)
    else 
    @follow_types = Itemtype.get_followable_types(params[:follow])
    @itemtypes =  Itemtype.where("itemtype in (?)", Item::ITEMTYPES).collect(&:id) if params[:follow] == 'Products'
    @itemtypes =  Itemtype.where("itemtype=?", params[:follow]).collect(&:id) if params[:follow] == 'Car' ||  params[:follow] == 'Mobile' || params[:follow] == 'Cycle' || params[:follow] == 'Camera' || params[:follow] == 'Tablet' || params[:follow] == 'Bike'
     if params[:follow].match("Preferences")
       
     
     @itemtypes_list =  Itemtype.where("itemtype in (?)", Item::ITEMTYPES-["Manufacturer","Car Group","Topic"])
     buying_plans(@user)
     end
    @article_categories = ArticleCategory.by_itemtype_id(0).map { |e|[e.name, e.id]  } 
    @followitems = Follow.for_follower(@user).where(:followable_type => @follow_types).paginate :page => params[:page],:per_page => 8
    @follow_item = @followitems.group_by(&:followable_type)
    end
    respond_to do|format|      
      format.html {render :layout => "product"}
    end
  end

  def add_review
    @item = Item.find(params[:id])
  end
  
  def add_photo
    @item = Item.find(params[:id])
  end
  
  def add_information
    @item = Item.find(params[:id])
  end
  def buying_plans(user)
    @buying_plans = BuyingPlan.where("user_id = ? and (deleted  IS NULL or deleted = 0)",   user.id)
  end
  
  #TODO. not restful
  def followers
    @user = User.find(params[:id])
    @followers = Follow.follow_type(['Plannto', 'Facebook']).for_followable(@user)
  end
end
