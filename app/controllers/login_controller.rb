class LoginController < ApplicationController
  include BasicAuthenticator

  before_filter :authenticate_client

  def login
    render text: @role.credentials.api_key
  end

  protected

  def authenticate_client
    perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
    raise Unauthorized, "Role not found" unless @role = authentication.authenticated_role
  end

  def basic_password_ok? credentials, password
    credentials.valid_password?(password)
  end
end
