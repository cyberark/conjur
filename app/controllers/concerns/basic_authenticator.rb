# frozen_string_literal: true

module BasicAuthenticator
  extend ActiveSupport::Concern
  
  included do
    include ActionController::HttpAuthentication::Basic::ControllerMethods
  end
  
  def perform_basic_authn
    authenticate_with_http_basic do |username, password|
      credentials = Credentials[Role.roleid_from_username(account, username)]
      if credentials && credentials.authenticate(password)
        authentication.authenticated_role = credentials.role
        authentication.basic_user = true
      end
    end if request.authorization =~ /^Basic / # we need to check the auth method.
    # authenticate_with_http_basic doesn't do that and freaks out randomly.
  end
end
