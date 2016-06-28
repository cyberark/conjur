module BasicAuthenticator
  def self.included(base)
    base.instance_eval do
      include ActionController::HttpAuthentication::Basic::ControllerMethods
    end
  end
  
  def perform_basic_authn
    authenticate_with_http_basic do |username, password|
      user = AuthnUser[username]
      if user && user.authenticate(password)
        authentication.basic_user = username
      end
    end if request.authorization =~ /^Basic / # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
  end
end