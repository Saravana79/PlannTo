class Users::RegistrationsController < Devise::RegistrationsController
  layout "product"
  def new
    @static_page = "true"
    @devise = "true"
    @invitation = Invitation.find_by_token(params[:token])
    @without_login = params[:type]
    build_resource
    resource.email = @invitation.email unless @invitation.nil?
  end

  def publisher_sign_up
    return redirect_to root_path if !current_user.blank?
    @static_page = "true"
    @devise = "true"
    @invitation = Invitation.find_by_token(params[:token])
    @without_login = params[:type]
    @publisher = Publisher.new
    build_resource
    resource.email = @invitation.email unless @invitation.nil?
  end

  def create
    # @static_page = "true"
    # @devise = "true"
    # @invitation = Invitation.find_by_token(params[:token])
    # @item =  @invitation.item unless @invitation.blank?
    # @without_login = params[:type]
    # #from devise
    # build_resource
    # if resource.save
    #   @invitation.accept(resource) unless @invitation.blank?
    #   if resource.active_for_authentication?
    #     sign_in(resource_name, resource)
    #   else
    #     expire_session_data_after_sign_in!
    #   end
    #     BuyingPlan.buying_plan_move_from_without_login(current_user,request.remote_ip)
    #     session[:buying_warning_message] = ''
    #     if @without_login!="without_login"
    #       if @item.nil?
    #         redirect_to  "/newuser_wizard", notice: "Successfully registered"
    #       else
    #         redirect_to  "/newuser_wizard?invitation=#{@invitation.id}", notice: "Successfully registered"
    #       end
    #    else
    #      buying_plan = BuyingPlan.where(:user_id => current_user.id,:deleted => false,:completed => false).first
    #      redirect_to  "#{buying_plan.preference_page_url}?type=create"
    #  end
    # else
    #   clean_up_passwords resource
    #   respond_with resource
    # end

    build_resource
    if resource.save
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
      else
        expire_session_data_after_sign_in!
      end
      redirect_to  admin_advertisements_path, notice: "Successfully registered"
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  def publisher_create
    @static_page = "true"
    @devise = "true"

    build_resource

    @publisher = Publisher.new(:publisher_url => params[:publisher_url], :contact_details => params[:contact_details], :name => params[:site_name])

    publisher_valid = @publisher.valid?
    if resource.valid? && publisher_valid && resource.save && @publisher.save!
      @user_relationship = UserRelationship.create(:user_id => resource.id, :relationship_id => @publisher.id, :relationship_type => "Publisher")
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
      else
        expire_session_data_after_sign_in!
      end

      redirect_to publishers_path, notice: "Successfully registered"
    else
      clean_up_passwords resource
      # respond_with resource
      render :publisher_sign_up
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
