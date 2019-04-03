# frozen_string_literal: true

require 'util/error_class'

module Authentication

  AuthenticatorNotFound = ::Util::ErrorClass.new(
    "'{0}' wasn't in the available authenticators"
  )

  InvalidCredentials = ::Util::ErrorClass.new(
    "Invalid credentials"
  )

  InvalidOrigin = ::Util::ErrorClass.new(
    "Invalid origin"
  )

  MissingRequestParam = ::Util::ErrorClass.new(
    "field '{0}' is missing or empty in request body"
  )

  module AuthnOidc

    ProviderDiscoveryTimeout = ::Util::ErrorClass.new(
      "OIDC provider discovery failed with timeout error (provider_uri='{0}'). Reason: '{1}'"
    )

    ProviderDiscoveryFailed = ::Util::ErrorClass.new(
      "OIDC provider discovery failed (provider_uri='{0}'). Reason: '{1}'"
    )

    ProviderFetchCertificateFailed = ::Util::ErrorClass.new(
      "Failed to fetch certificate from OIDC provider (provider_uri='{0}'). Reason: '{1}'"
    )

    IdTokenFieldNotFoundOrEmpty = ::Util::ErrorClass.new(
      "Field '{0}' not found or empty in ID Token"
    )

    IdTokenInvalidFormat = ::Util::ErrorClass.new(
      "Invalid ID Token Format (3rdPartyError ='{0}')"
    )

    IdTokenVerifyFailed = ::Util::ErrorClass.new(
      "ID Token verification failed (3rdPartyError ='{0}')"
    )

    IdTokenExpired = ::Util::ErrorClass.new(
      "ID Token Expired"
    )

  end

end
