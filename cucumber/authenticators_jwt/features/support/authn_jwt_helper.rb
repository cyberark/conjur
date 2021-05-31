# frozen_string_literal: true

# Utility methods for JWT authenticator

module AuthnJwtHelper
  include AuthenticatorHelpers

  ACCOUNT = 'cucumber'.freeze
  SERVICE_ID = 'raw'.freeze

  def authenticate_jwt_token(jwt_token)
    path = "#{conjur_hostname}/authn-jwt/#{SERVICE_ID}/#{ACCOUNT}/authenticate"

    payload = {}
    payload["jwt"] = jwt_token

    post(path, payload)
  end

  def create_jwt_secret(variable_name, value)
    path = "#{ACCOUNT}:variable:conjur/authn-jwt/#{SERVICE_ID}"
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

end

World(AuthnJwtHelper)
