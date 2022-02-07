# frozen_string_literal: true

# Utility methods for JWT authenticator
module AuthnJwtHelper

  ACCOUNT = 'cucumber'
  DEFAULT_SERVICE_ID = 'raw'
  OIDC_PROVIDER_SERVICE_ID = "keycloak"

  def authenticate_jwt_token(jwt_token, service_id = DEFAULT_SERVICE_ID)
    authenticate_jwt(jwt_token: jwt_token, service_id: service_id)
  end

  def authenticate_jwt(jwt_token:, service_id:)
    path = "#{conjur_hostname}/authn-jwt/#{service_id}/#{ACCOUNT}/authenticate"
    payload = {
      "jwt" => jwt_token
    }
    post(path, payload)
  end

  def authenticate_jwt_with_oidc_as_provider_uri(id_token: parsed_id_token)
    authenticate_jwt(jwt_token: id_token, service_id: OIDC_PROVIDER_SERVICE_ID)
  end

  def authenticate_jwt_with_url_identity(jwt_token, account_name, service_id = DEFAULT_SERVICE_ID)
    path = "#{conjur_hostname}/authn-jwt/#{service_id}/#{ACCOUNT}/#{account_name}/authenticate"
    payload = {
      "jwt" => jwt_token
    }
    post(path, payload)
  end

  def create_jwt_secret_with_oidc_as_provider_uri(variable_name:, value:, service_id: OIDC_PROVIDER_SERVICE_ID)
    create_jwt_secret(variable_name: variable_name, value: value, service_id: service_id)
  end

  def create_jwt_secret(variable_name:, value:, service_id: DEFAULT_SERVICE_ID)
    path = "#{ACCOUNT}:variable:conjur/authn-jwt/#{service_id}"
    Secret.create(resource_id: "#{path}/#{variable_name}", value: value)
  end

  def create_public_keys_from_response_body(type: "jwks")
    public_keys = {
      "type" => type,
      "value" => JSON.parse(@response_body)
    }
    create_jwt_secret(
      variable_name: "public-keys",
      value: JSON.dump(public_keys)
    )
  end

end

World(AuthnJwtHelper)
