class AccountsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_user_info
  def index
    
  end

  def update
    if current_user.update_attributes(params[:user]) && current_user.errors.blank?
        params[:user][:avatar][:user_id] = current_user.id
      if  Avatar.find_or_create_by_user_id(current_user.id) && current_user.avatar.update_attributes(params[:user][:avatar])
        flash[:notice] = "Account update successfully"
      else
        flash[:notice] = "please upload the avatar from profile page"
      end
    end
    render :action => :index
  end

  def get_user_info
    @user = current_user
    @facebook_user = facebook_profile
  end

  def profile
    require 'will_paginate/array'

    @follow_types = get_followable_types(params[:follow])
    @follow_item = Follow.for_follower(current_user).where(:followable_type => @follow_types).group_by(&:followable_type)
    respond_to do|format|      
      format.html {render :layout => "product"}
    end
  end

  private
  def get_followable_types(item_type)
    case item_type
      when 'Car'
        ['Car', 'Manufacturer', 'CarGroup']
      when 'Mobile'
        ['Mobile']
      else
        ['Car', 'Manufacturer', 'CarGroup']
    end
  end
end
