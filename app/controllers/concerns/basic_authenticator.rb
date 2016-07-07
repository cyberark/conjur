module BasicAuthenticator
  extend ActiveSupport::Concern
  
  included do
    include ActionController::HttpAuthentication::Basic::ControllerMethods
  end
  
  def perform_basic_authn
    authenticate_with_http_basic do |username, password|
      credentials = Credentials[Role.roleid_from_username(username)]
      if credentials && credentials.authenticate(password)
        authentication.basic_user = username
      end
    end if request.authorization =~ /^Basic / # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
  end
end
