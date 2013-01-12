class Users::RegistrationsController < Devise::RegistrationsController
  layout "product"
  def new
    @static_page = "true"
    @devise = "true"
    @invitation = Invitation.find_by_token(params[:token])
    build_resource
    resource.email = @invitation.email unless @invitation.nil?
  end

  def create
    @static_page = "true"
    @devise = "true"
    @invitation = Invitation.find_by_token(params[:token])
    @item =  @invitation.item unless @invitation.blank?
    
    #from devise
    build_resource
    if resource.save
      @invitation.accept(resource) unless @invitation.blank?
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
      else
        expire_session_data_after_sign_in!
      end
      
      if Rails.env.development?
        BuyingPlan.buying_plan_move_from_without_login(current_user,request.remote_ip)
      end  
      
      if @item.nil?
        redirect_to  "/newuser_wizard", notice: "Successfully registered"
      else
        redirect_to  "/newuser_wizard?invitation=#{@invitation.id}", notice: "Successfully registered"
      end 
  
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
  
  def update
  if resource.update_without_current_password(params[resource_name])
    set_flash_message :notice, :updated
    sign_in resource_name, resource, :bypass => true
    redirect_to "/#{resource.username}"
  else
    clean_up_passwords(resource)
    redirect_to "/#{resource.username}"
  end
end
end
