# frozen_string_literal: true

# Utility methods for JWT authenticator

module AuthnJwtHelper
  include AuthenticatorHelpers

  ACCOUNT = 'cucumber'
  SERVICE_ID = 'raw'

  def authenticate_jwt_token(jwt_token, service_id = SERVICE_ID)
    path = "#{conjur_hostname}/authn-jwt/#{service_id}/#{ACCOUNT}/authenticate"
    payload = {
      "jwt" => jwt_token
    }
    post(path, payload)
  end

  def authenticate_jwt_with_url_identity(jwt_token, account_name, service_id = SERVICE_ID)
    path = "#{conjur_hostname}/authn-jwt/#{service_id}/#{ACCOUNT}/#{account_name}/authenticate"
    payload = {
      "jwt" => jwt_token
    }
    post(path, payload)
  end

  def create_jwt_secret(variable_name, value)
    path = "#{ACCOUNT}:variable:conjur/authn-jwt/#{SERVICE_ID}"
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

end

World(AuthnJwtHelper)
