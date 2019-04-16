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

  module Security

    NotWhitelisted = ::Util::ErrorClass.new(
      "'{0}' not whitelisted in CONJUR_AUTHENTICATORS"
    )

    ServiceNotDefined = ::Util::ErrorClass.new(
      "Webservice '{0}' is not defined in the Conjur policy"
    )

    UserNotAuthorizedInConjur = ::Util::ErrorClass.new(
      "User '{0}' is not authorized in the Conjur policy"
    )

    UserNotDefinedInConjur = ::Util::ErrorClass.new(
      "User '{0}' is not defined in Conjur"
    )

    AccountNotDefined = ::Util::ErrorClass.new(
      "account '{0}' is not defined in Conjur"
    )

  end

  module RequestBody

    MissingRequestParam = ::Util::ErrorClass.new(
      "field '{0}' is missing or empty in request body"
    )

  end

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

  module AuthnIam

    InvalidAWSHeaders = ::Util::ErrorClass.new(
      "'Invalid or Expired AWS Headers: {0}"
    )

  end

  module AuthnK8s

    WebserviceNotFound = ::Util::ErrorClass.new(
      "Webservice '{0}' wasn't found"
    )

    HostNotFound = ::Util::ErrorClass.new(
      "Host '{0}' wasn't found"
    )

    HostNotAuthorized = ::Util::ErrorClass.new(
      "'{0}' does not have 'authenticate' privilege on {1}"
    )

    CSRIsMissingSpiffeId = ::Util::ErrorClass.new(
      'CSR must contain SPIFFE ID SAN'
    )

    CSRNamespaceMismatch = ::Util::ErrorClass.new(
      "Namespace in SPIFFE ID '{0}' must match namespace implied by common name ('{1}')"
    )

    PodNotFound = ::Util::ErrorClass.new(
      "No Pod found for podname '{0}' in namespace '{1}'"
    )

    ScopeNotSupported = ::Util::ErrorClass.new(
      "Resource type '{0}' identity scope is not supported in this version " +
        "of authn-k8s"
    )

    ControllerNotFound = ::Util::ErrorClass.new(
      "Kubernetes {0} {1} not found in namespace {2}"
    )

    CertInstallationError = ::Util::ErrorClass.new(
      "Cert could not be copied to pod: {0}"
    )

    ContainerNotFound = ::Util::ErrorClass.new(
      "Container {0} was not found for requesting pod"
    )

    MissingClientCertificate = ::Util::ErrorClass.new(
      "The client SSL cert is missing from the header"
    )

    UntrustedClientCertificate = ::Util::ErrorClass.new(
      "Client certificate cannot be verified by certification authority"
    )

    CommonNameDoesntMatchHost = ::Util::ErrorClass.new(
      "Client certificate CN must match host name. Cert CN: {0}. " +
        "Host name: {1}. "
    )

    ClientCertificateExpired = ::Util::ErrorClass.new(
      "Client certificate expired"
    )

    CommandTimedOut = ::Util::ErrorClass.new(
      "Command timed out in container '{0}' of pod '{1}'"
    )

    module KubeClientFactory

      MissingServiceAccountDir = ::Util::ErrorClass.new(
        "Kubernetes serviceaccount dir '{0}' does not exist"
      )

      MissingEnvVar = ::Util::ErrorClass.new(
        "Expected ENV variable '{0}' is not set"
      )

    end
  end
end
