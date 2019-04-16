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

  NotWhitelisted = ::Util::ErrorClass.new(
    "'{0}' not whitelisted in CONJUR_AUTHENTICATORS")

  ServiceNotDefined = ::Util::ErrorClass.new(
    "Webservice '{0}' is not defined in the Conjur policy")

  NotAuthorizedInConjur = ::Util::ErrorClass.new(
    "User '{0}' is not authorized in the Conjur policy")

  NotDefinedInConjur = ::Util::ErrorClass.new(
    "User '{0}' is not defined in Conjur")

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

    AdminAuthenticationDenied = ::Util::ErrorClass.new(
      "admin user is not allowed to authenticate with OIDC"
    )
  end

end
