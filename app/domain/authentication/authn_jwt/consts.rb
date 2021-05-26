# frozen_string_literal: true

module Authentication
  module AuthnJwt
    PROVIDER_URI_RESOURCE_NAME = "provider-uri".freeze
    JWKS_URI_RESOURCE_NAME = "jwks-uri".freeze
    ISSUER_RESOURCE_NAME = "issuer".freeze
    IDENTITY_FIELD_VARIABLE = "token-app-property".freeze
    IDENTITY_NOT_RETRIEVED_YET = "Identity not retrieved yet".freeze
    PRIVILEGE_AUTHENTICATE="authenticate".freeze
    ISS_CLAIM_NAME = "iss".freeze
    EXP_CLAIM_NAME = "exp".freeze
    NBF_CLAIM_NAME = "nbf".freeze
    IAT_CLAIM_NAME = "iat".freeze
    RSA_ALGORITHMS = %w[RS256 RS384 RS512].freeze
    ECDSA_ALGORITHMS = %w[ES256 ES384 ES512].freeze
    SUPPORTED_ALGORITHMS = (RSA_ALGORITHMS + ECDSA_ALGORITHMS).freeze
    CACHE_REFRESHES_PER_INTERVAL = 10
    CACHE_RATE_LIMIT_INTERVAL = 300 # 300 seconds (every 5 mins)
    CACHE_MAX_CONCURRENT_REQUESTS = 3
  end
end
