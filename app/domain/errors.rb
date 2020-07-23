# frozen_string_literal: true

module Errors
  module Conjur

    RequiredResourceMissing = ::Util::TrackableErrorClass.new(
      msg:  "Missing required resource: {0-resource-name}",
      code: "CONJ00036E"
    )

    RequiredSecretMissing = ::Util::TrackableErrorClass.new(
      msg:  "Missing value for resource: {0-resource-name}",
      code: "CONJ00037E"
    )

    InsufficientPasswordComplexity = ::Util::TrackableErrorClass.new(
      msg:  "The password you have chosen does not meet the complexity requirements. " \
          "Choose a password that includes: 12-128 characters, 2 uppercase letters, " \
          "2 lowercase letters, 1 digit, 1 special character",
      code: "CONJ00046E"
    )

  end

  module Authentication

    AuthenticatorNotFound = ::Util::TrackableErrorClass.new(
      msg:  "Authenticator '{0-authenticator-name}' is not implemented in Conjur",
      code: "CONJ00001E"
    )

    InvalidCredentials = ::Util::TrackableErrorClass.new(
      msg:  "Invalid credentials",
      code: "CONJ00002E"
    )

    InvalidOrigin = ::Util::TrackableErrorClass.new(
      msg:  "Invalid origin",
      code: "CONJ00003E"
    )

    StatusNotImplemented = ::Util::TrackableErrorClass.new(
      msg:  "Status check not implemented for authenticator '{0-authenticator-name}'",
      code: "CONJ00056E"
    )

    IllegalConstraintCombinations = ::Util::TrackableErrorClass.new(
      msg:  "Application identity includes an illegal resource constraint combination - '{0-constraints}'",
      code: "CONJ00055E"
    )

    module AuthenticatorClass

      DoesntStartWithAuthn = ::Util::TrackableErrorClass.new(
        msg:  "'{0-authenticator-parent-name}' is not a valid authenticator "\
            "parent module because it does not begin with 'Authn'",
        code: "CONJ00038E"
      )

      NotNamedAuthenticator = ::Util::TrackableErrorClass.new(
        msg:  "'{0-authenticator-name}' is not a valid authenticator name. " \
            "The actual class implementing the authenticator must be named 'Authenticator'",
        code: "CONJ00039E"
      )

      MissingValidMethod = ::Util::TrackableErrorClass.new(
        msg:  "'{0-authenticator-name}' is not a valid authenticator because " \
            "it does not have a `:valid?(input)` method.",
        code: "CONJ00040E"
      )

    end

    module Security

      AuthenticatorNotWhitelisted = ::Util::TrackableErrorClass.new(
        msg:  "'{0-authenticator-name}' is not enabled",
        code: "CONJ00004E"
      )

      WebserviceNotFound = ::Util::TrackableErrorClass.new(
        msg:  "Webservice '{0-webservice-name}' not found",
        code: "CONJ00005E"
      )

      RoleNotAuthorizedOnResource = ::Util::TrackableErrorClass.new(
        msg:  "'{0-role-name}' does not have '{1-privilege}' privilege on {2-resource-name}",
        code: "CONJ00006E"
      )

      RoleNotFound = ::Util::TrackableErrorClass.new(
        msg:  "'{0-role-name}' not found",
        code: "CONJ00007E"
      )

      AccountNotDefined = ::Util::TrackableErrorClass.new(
        msg:  "Account '{0-account-name}' is not defined in Conjur",
        code: "CONJ00008E"
      )

    end

    module RequestBody

      MissingRequestParam = ::Util::TrackableErrorClass.new(
        msg:  "Field '{0-field-name}' is missing or empty in request body",
        code: "CONJ00009E"
      )

    end

    module OAuth

      ProviderDiscoveryTimeout = ::Util::TrackableErrorClass.new(
        msg:  "Failed to discover Identity Provider with timeout error (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00010E"
      )

      ProviderDiscoveryFailed = ::Util::TrackableErrorClass.new(
        msg:  "Failed to discover Identity Provider (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00011E"
      )

      FetchProviderKeysFailed = ::Util::TrackableErrorClass.new(
        msg:  "Failed to fetch keys from Identity Provider (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00012E"
      )

    end

    module Jwt

      TokenExpired = ::Util::TrackableErrorClass.new(
        msg:  "Token expired",
        code: "CONJ00016E"
      )

      TokenDecodeFailed = ::Util::TrackableErrorClass.new(
        msg:  "Failed to decode token (3rdPartyError ='{0}')",
        code: "CONJ00035E"
      )

      TokenVerificationFailed = ::Util::TrackableErrorClass.new(
        msg:  "Failed to verify token (3rdPartyError ='{0}')",
        code: "CONJ00015E"
      )

    end

    module AuthnOidc

      IdTokenFieldNotFoundOrEmpty = ::Util::TrackableErrorClass.new(
        msg:  "Field '{0-field-name}' not found or empty in ID token. " \
            "This field is defined in the id-token-user-property variable.",
        code: "CONJ00013E"
      )

      AdminAuthenticationDenied = ::Util::TrackableErrorClass.new(
        msg:  "Admin user is not allowed to authenticate with OIDC",
        code: "CONJ00017E"
      )

    end

    module AuthnIam

      InvalidAWSHeaders = ::Util::TrackableErrorClass.new(
        msg:  "Invalid or expired AWS headers: {0}",
        code: "CONJ00018E"
      )

      VerificationError = ::Util::TrackableLogMessageClass.new(
        msg:  "Verification of IAM identity failed with exception: {0-exception}",
        code: "CONJ00063E"
      )

      IdentityVerificationErrorCode = ::Util::TrackableLogMessageClass.new(
        msg:  "Verification of IAM identity failed with HTTP code: {0-http-code}",
        code: "CONJ00064E"
      )

    end

    module AuthnK8s

      CSRIsMissingSpiffeId = ::Util::TrackableErrorClass.new(
        msg:  'CSR must contain SPIFFE ID SAN',
        code: "CONJ00022E"
      )

      PodNotFound = ::Util::TrackableErrorClass.new(
        msg:  "No pod found for '{0-pod-name}' in namespace '{1}'",
        code: "CONJ00024E"
      )

      ScopeNotSupported = ::Util::TrackableErrorClass.new(
        msg:  "Resource type '{0}' is not a supported application identity. " \
            "The supported resources are '{1}'",
        code: "CONJ00025E"
      )

      K8sResourceNotFound = ::Util::TrackableErrorClass.new(
        msg:  "Kubernetes {0-resource-name} {1-object-name} not found in namespace {2}",
        code: "CONJ00026E"
      )

      CertInstallationError = ::Util::TrackableErrorClass.new(
        msg:  "Certificate could not be copied to pod: {0}",
        code: "CONJ00027E"
      )

      ContainerNotFound = ::Util::TrackableErrorClass.new(
        msg:  "Container {0} was not found in the pod. Host id: {1}",
        code: "CONJ00028E"
      )

      MissingClientCertificate = ::Util::TrackableErrorClass.new(
        msg:  "Client SSL certificate is missing from the header",
        code: "CONJ00029E"
      )

      UntrustedClientCertificate = ::Util::TrackableErrorClass.new(
        msg:  "Client certificate cannot be verified by certification authority",
        code: "CONJ00030E"
      )

      CommonNameDoesntMatchHost = ::Util::TrackableErrorClass.new(
        msg:  "Client certificate CN must match host name. Cert CN: {0}. " \
            "Host name: {1}.",
        code: "CONJ00031E"
      )

      ClientCertificateExpired = ::Util::TrackableErrorClass.new(
        msg:  "Client certificate expired",
        code: "CONJ00032E"
      )

      CommandTimedOut = ::Util::TrackableErrorClass.new(
        msg:  "Command timed out in container '{0}' of pod '{1}'",
        code: "CONJ00033E"
      )

      MissingServiceAccountDir = ::Util::TrackableErrorClass.new(
        msg:  "Kubernetes serviceaccount dir '{0}' does not exist",
        code: "CONJ00034E"
      )

      UnknownK8sResourceType = ::Util::TrackableErrorClass.new(
        msg:  "Unknown Kubernetes resource type '{0}'",
        code: "CONJ00041E"
      )

      InvalidApiUrl = ::Util::TrackableErrorClass.new(
        msg:  "Received invalid Kubernetes API url: '{0}'",
        code: "CONJ00042E"
      )

      MissingCertificate = ::Util::TrackableErrorClass.new(
        msg:  "No Kubernetes API certificate available",
        code: "CONJ00043E"
      )

      MissingNamespaceConstraint = ::Util::TrackableErrorClass.new(
        msg:  "Host does not have a namespace constraint",
        code: "CONJ00045E"
      )

      NamespaceMismatch = ::Util::TrackableErrorClass.new(
        msg:  "Namespace in SPIFFE ID '{0-spiffe-namespace}' must match namespace " \
            "implied by application identity '{1-application-identity-namespace}'",
        code: "CONJ00023E"
      )

      CSRMissingCNEntry = ::Util::TrackableErrorClass.new(
        msg:  "CSR [subject: '{0-subject}', spiffe_id: '{1-spiffe-id}'] must have a CN (common name) entry.",
        code: "CONJ00058E"
      )

      CertMissingCNEntry = ::Util::TrackableErrorClass.new(
        msg:  "Cert [subject: '{0-subject}', san: '{1-san}'] must have a CN (common name) entry.",
        code: "CONJ00059E"
      )

      PodNameMismatchError = ::Util::TrackableErrorClass.new(
        msg:  "Pod: {0-pod-name} does not match: {1-actual-resource-name}.",
        code: "CONJ00060E"
      )

      PodRelationMismatchError = ::Util::TrackableErrorClass.new(
        msg:  "Pod: {0-pod-name}, {1-resource-type}: {2-expected-resource-name}, does not match: " \
                  "{3-actual-resource-name}.",
        code: "CONJ00061E"
      )

      PodMissingRelationError = ::Util::TrackableErrorClass.new(
        msg:  "Pod: {0-pod-name} does not belong to a {1-resource-type}.",
        code: "CONJ00062E"
      )

      InvalidHostId = ::Util::TrackableErrorClass.new(
        msg:  "Invalid Kubernetes host id: {0}. Must end with <namespace>/<resource_type>/<resource_id>",
        code: "CONJ00048E"
      )
    end

    module AuthnAzure

      RoleMissingConstraint = ::Util::TrackableErrorClass.new(
        msg:  "Role does not have the required constraint: {0-constraint}",
        code: "CONJ00057E"
      )

      InvalidApplicationIdentity = ::Util::TrackableErrorClass.new(
        msg:  "Application identity field '{0-field-name}' does not match " \
            "application identity in Azure token",
        code: "CONJ00049E"
      )

      ConstraintNotSupported = ::Util::TrackableErrorClass.new(
        msg:  "Constraint type '{0}' is not a supported application identity. " \
            "The supported resources are '{1}'",
        code: "CONJ00050E"
      )

      TokenFieldNotFoundOrEmpty = ::Util::TrackableErrorClass.new(
        msg:  "Field '{0-field-name}' not found or empty in token",
        code: "CONJ00051E"
      )

      XmsMiridParseError = ::Util::TrackableErrorClass.new(
        msg:  "Failed to parse xms_mirid {0}. Reason: {1}",
        code: "CONJ00052E"
      )

      MissingRequiredFieldsInXmsMirid = ::Util::TrackableErrorClass.new(
        msg:  "Required fields {0} are missing in xms_mirid {1}",
        code: "CONJ00053E"
      )

      InvalidProviderFieldsInXmsMirid = ::Util::TrackableErrorClass.new(
        msg:  "Provider fields are in invalid format in xms_mirid {1}. " \
                "xms_mirid must contain the resource provider namespace, the " \
                "resource type, and the resource name",
        code: "CONJ00054E"
      )
    end
  end

  module Util

    ConcurrencyLimitReachedBeforeCacheInitialization = ::Util::TrackableErrorClass.new(
      msg:  "Concurrency limited cache reached before cache initialized",
      code: "CONJ00044E"
    )
  end

  module System
    EmptyConjurDataKey = ::Util::TrackableErrorClass.new(
      msg:  "CONJUR_DATA_KEY is empty. " \
            "Try loading the data key as an environment variable.",
      code: "CONJ00065E"
    )

    InvalidConjurDataKey = ::Util::TrackableErrorClass.new(
      msg:  "Invalid CONJUR_DATA_KEY. " \
            "The key provided does not match the key that the database was created with.",
      code: "CONJ00066E"
    )
  end
end
