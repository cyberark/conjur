class LoginController < ApplicationController
  include BasicAuthenticator

  # Perform the authentication strategy.
  before_filter :authenticate_client

  # Ensure that the referenced role exists.
  before_filter :find_role

  # Ensure the credentials exist if they will be accessed or modified.
  before_filter :ensure_credentials
    
  def login
    render text: @role.credentials.api_key
  end
  
  protected
  
  def authenticate_client
    perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
  end

  def find_role
    raise Unauthorized, "Role not found" unless @role = authentication.apply_to_role
  end
  
  # Ensure that the current role has credentials.
  def ensure_credentials
    @role.credentials ||= Credentials.new(role: @role)
  end
end
