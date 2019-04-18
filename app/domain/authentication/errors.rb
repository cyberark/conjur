# frozen_string_literal: true

require 'util/error_class'

module Authentication

  AuthenticatorNotFound = ::Util::ErrorClassWithCode.new(
    msg: "'{0}' wasn't in the available authenticators",
    code: "CONJ00001E"
  )

  InvalidCredentials = ::Util::ErrorClassWithCode.new(
    msg: "Invalid credentials",
    code: "CONJ00002E"
  )

  InvalidOrigin = ::Util::ErrorClassWithCode.new(
    msg: "Invalid origin",
    code: "CONJ00003E"
  )

  module Security

    NotWhitelisted = ::Util::ErrorClassWithCode.new(
      msg: "'{0}' not whitelisted in CONJUR_AUTHENTICATORS",
      code: "CONJ00004E"
    )

    ServiceNotDefined = ::Util::ErrorClassWithCode.new(
      msg: "Webservice '{0}' is not defined in the Conjur policy",
      code: "CONJ00005E"
    )

    UserNotAuthorizedInConjur = ::Util::ErrorClassWithCode.new(
      msg: "User '{0}' is not authorized in the Conjur policy",
      code: "CONJ00006E"
    )

    UserNotDefinedInConjur = ::Util::ErrorClassWithCode.new(
      msg: "User '{0}' is not defined in Conjur",
      code: "CONJ00007E"
    )

    AccountNotDefined = ::Util::ErrorClassWithCode.new(
      msg: "account '{0}' is not defined in Conjur",
      code: "CONJ00008E"
    )

  end

  module RequestBody

    MissingRequestParam = ::Util::ErrorClassWithCode.new(
      msg: "field '{0}' is missing or empty in request body",
      code: "CONJ00009E"
    )

  end

  module AuthnOidc

    ProviderDiscoveryTimeout = ::Util::ErrorClassWithCode.new(
      msg: "OIDC provider discovery failed with timeout error (provider_uri='{0}'). Reason: '{1}'",
      code: "CONJ00010E"
    )

    ProviderDiscoveryFailed = ::Util::ErrorClassWithCode.new(
      msg: "OIDC provider discovery failed (provider_uri='{0}'). Reason: '{1}'",
      code: "CONJ00011E"
    )

    ProviderFetchCertificateFailed = ::Util::ErrorClassWithCode.new(
      msg: "Failed to fetch certificate from OIDC provider (provider_uri='{0}'). Reason: '{1}'",
      code: "CONJ00012E"
    )

    IdTokenFieldNotFoundOrEmpty = ::Util::ErrorClassWithCode.new(
      msg: "Field '{0}' not found or empty in ID Token",
      code: "CONJ00013E"
    )

    IdTokenInvalidFormat = ::Util::ErrorClassWithCode.new(
      msg: "Invalid ID Token Format (3rdPartyError ='{0}')",
      code: "CONJ00014E"
    )

    IdTokenVerifyFailed = ::Util::ErrorClassWithCode.new(
      msg: "ID Token verification failed (3rdPartyError ='{0}')",
      code: "CONJ00015E"
    )

    IdTokenExpired = ::Util::ErrorClassWithCode.new(
      msg: "ID Token Expired",
      code: "CONJ00016E"
    )

    AdminAuthenticationDenied = ::Util::ErrorClassWithCode.new(
      msg: "admin user is not allowed to authenticate with OIDC",
      code: "CONJ00017E"
    )

  end

  module AuthnIam

    InvalidAWSHeaders = ::Util::ErrorClassWithCode.new(
      msg: "'Invalid or Expired AWS Headers: {0}",
      code: "CONJ00018E"
    )

  end

  module AuthnK8s

    WebserviceNotFound = ::Util::ErrorClassWithCode.new(
      msg: "Webservice '{0}' wasn't found",
      code: "CONJ00019E"
    )

    HostNotFound = ::Util::ErrorClassWithCode.new(
      msg: "Host '{0}' wasn't found",
      code: "CONJ00020E"
    )

    HostNotAuthorized = ::Util::ErrorClassWithCode.new(
      msg: "'{0}' does not have 'authenticate' privilege on {1}",
      code: "CONJ00021E"
    )

    CSRIsMissingSpiffeId = ::Util::ErrorClassWithCode.new(
      msg: 'CSR must contain SPIFFE ID SAN',
      code: "CONJ00022E"
    )

    CSRNamespaceMismatch = ::Util::ErrorClassWithCode.new(
      msg: "Namespace in SPIFFE ID '{0}' must match namespace implied by common name ('{1}')",
      code: "CONJ00023E"
    )

    PodNotFound = ::Util::ErrorClassWithCode.new(
      msg: "No Pod found for podname '{0}' in namespace '{1}'",
      code: "CONJ00024E"
    )

    ScopeNotSupported = ::Util::ErrorClassWithCode.new(
      msg: "Resource type '{0}' identity scope is not supported in this version " +
        "of authn-k8s",
      code: "CONJ00025E"
    )

    ControllerNotFound = ::Util::ErrorClassWithCode.new(
      msg: "Kubernetes {0} {1} not found in namespace {2}",
      code: "CONJ00026E"
    )

    CertInstallationError = ::Util::ErrorClassWithCode.new(
      msg: "Cert could not be copied to pod: {0}",
      code: "CONJ00027E"
    )

    ContainerNotFound = ::Util::ErrorClassWithCode.new(
      msg: "Container {0} was not found for requesting pod",
      code: "CONJ00028E"
    )

    MissingClientCertificate = ::Util::ErrorClassWithCode.new(
      msg: "The client SSL cert is missing from the header",
      code: "CONJ00029E"
    )

    UntrustedClientCertificate = ::Util::ErrorClassWithCode.new(
      msg: "Client certificate cannot be verified by certification authority",
      code: "CONJ00030E"
    )

    CommonNameDoesntMatchHost = ::Util::ErrorClassWithCode.new(
      msg: "Client certificate CN must match host name. Cert CN: {0}. " +
        "Host name: {1}. ",
      code: "CONJ00031E"
    )

    ClientCertificateExpired = ::Util::ErrorClassWithCode.new(
      msg: "Client certificate expired",
      code: "CONJ00032E"
    )

    CommandTimedOut = ::Util::ErrorClassWithCode.new(
      msg: "Command timed out in container '{0}' of pod '{1}'",
      code: "CONJ00033E"
    )

    module KubeClientFactory

      MissingServiceAccountDir = ::Util::ErrorClassWithCode.new(
        msg: "Kubernetes serviceaccount dir '{0}' does not exist",
        code: "CONJ00034E"
      )

      MissingEnvVar = ::Util::ErrorClassWithCode.new(
        msg: "Expected ENV variable '{0}' is not set",
        code: "CONJ00035E"
      )

    end
  end
end
