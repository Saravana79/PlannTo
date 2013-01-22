class Users::SessionsController < Devise::SessionsController
  layout "product"
  skip_before_filter :check_authentication, :store_session_url
  skip_before_filter :facebook_friends
  skip_before_filter :require_no_authentication, :only => [ :new, :create ] #, :if => request.xhr?
   prepend_before_filter :allow_params_authentication!, :only => :create
  #skip_before_filter :allow_params_authentication!, :only => :create #, :if => request.xhr?
  def new
    @static_page = "true"
    @devise = "true"
    return redirect_to root_url unless current_user.blank?
    super
  end


  def create
     @static_page = "true"
     @devise = "true"
    # resource = warden.authenticate!(auth_options)
    resource = warden.authenticate(auth_options)
 # if resource
    unless request.xhr? && !authentication.user.present?
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    BuyingPlan.buying_plan_move_from_without_login_for_has_account(current_user,request.remote_ip)  
    sign_in(resource_name, resource)
    if  session[:invitation].blank? 
      respond_with resource, :location => after_sign_in_path_for(resource)
    else
      redirect_to "#{session[:invitation]}" 
    end 
        
    #else
   
    #  if user_signed_in?
        #ajax signed in
     #   $logged_in = true

     # else
     #   $logged_in = false
        #ajax sign in failed.
    #  end
    end
    rescue #temporary solution for produce exception after login fail.
      sign_out(resource_name)
      @rescue = "true"
     render :new 
  end

  def auth_options
    unless request.xhr?
    { :scope => resource_name, :recall => "#{controller_path}#new" }
    else
      logger.info "#{resource_name}"
      {:scope => :user}
    end
  end

end
