class Users::RegistrationsController < Devise::RegistrationsController

  def new
    @invitation = Invitation.find_by_token(params[:token])
    build_resource
    resource.email = @invitation.email
  end

  def create
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
      if @item.nil?
        redirect_to  mobiles_url, notice: "Successfully registered"
      else
        redirect_to @item.get_url || mobiles_url, notice: "Successfully registered"
      end 
   
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
  
  
end
