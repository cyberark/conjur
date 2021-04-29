# frozen_string_literal: true

module Authentication
  module AuthnJwt

    PROVIDER_URI_RESOURCE_NAME = "provider-uri"
    JWKS_URI_RESOURCE_NAME = "jwks-uri"
    ISSUER_RESOURCE_NAME = "issuer"
    AUTHN_JWT_RESOURCE_PREFIX = "cucumber:variable:conjur/authn-jwt"
    JWT_ID_FIELD_NAME_VARIABLE = "token-app-property"
  end
end
