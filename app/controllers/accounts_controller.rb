class AccountsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_user_info
  def index
    
  end

  def update
    if current_user.update_attributes(params[:user]) && current_user.errors.blank?
      begin
        params[:user][:avatar][:user_id] = current_user.id
        current_user.avatar.update_attributes(params[:user][:avatar])
      rescue
        flash[:notice] = "please upload the avatar from profile page"
      end
      flash[:message] = "Account update successfully"
    end      
    render :action => :index
  end

  def get_user_info
    @user = current_user
    @facebook_user = facebook_profile
  end

  def profile
    require 'will_paginate/array'

    @follow_item = Follow.for_follower(current_user).where(:followable_type => get_followable_types(params[:follow])).group_by(&:followable_type)
    @car_items = get_array(@follow_item['Car']) + get_array(@follow_item['CarGroup']) + get_array(@follow_item['Manufacturer'])
    @car_items = @car_items.paginate(:page => params["page"], :per_page => 8) rescue [].paginate
    render :layout => "product"
  end

  private
  def get_array(array_obj)
    array_obj.blank? ?  [] : array_obj
  end

  def get_followable_types(item_type)
    case item_type
      when 'Car'
        ['Car', 'Manufacturer', 'CarGroup']
      when 'Mobile'
        ['Mobile']      
    end
  end
end
