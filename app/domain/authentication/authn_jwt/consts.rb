# frozen_string_literal: true

module Authentication
  module AuthnJwt
    PROVIDER_URI_RESOURCE_NAME = "provider-uri"
    JWKS_URI_RESOURCE_NAME = "jwks-uri"
    ISSUER_RESOURCE_NAME = "issuer"
    IDENTITY_FIELD_VARIABLE = "token-app-property"
    ISS_CLAIM_NAME = "iss"
    EXP_CLAIM_NAME = "exp"
    NBF_CLAIM_NAME = "nbf"
    IAT_CLAIM_NAME = "iat"
  end
end
