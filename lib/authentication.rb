module Authentication

  class Unauthorized < StandardError; end

  def self.included(base)
    base.send(:include, Authentication::HelperMethods)
    base.send(:include, Authentication::ControllerMethods)
  end

  module HelperMethods

    def facebook_current_user
      @facebook_user ||= Facebook.find(session[:current_user])
      if !@facebook_user.blank? && current_user.blank?
        @facebook_user.create_user
      end
      @current_user ||= @facebook_user.user

    rescue ActiveRecord::RecordNotFound
      nil
    end

    def facebook_profile
      @facebook_user.blank? ? nil : @facebook_user.profile
    end

    def authenticated?
      !facebook_current_user.blank?
    end

  end

  module ControllerMethods

    def require_authentication
      authenticate Facebook.find_by_id(session[:current_user])
    rescue Unauthorized => e
      redirect_to root_url and return false
    end

    def authenticate(user)
      raise Unauthorized unless user
      session[:current_user] = user.id
    end

    def unauthenticate
#      current_user.destroy if current_user
      @current_user = session[:current_user] = nil
    end

  end

end