# frozen_string_literal: true

module Errors
  module Conjur

    RequiredResourceMissing = ::Util::TrackableErrorClass.new(
      msg: "Missing required resource: {0-resource-name}",
      code: "CONJ00036E"
    )

    RequiredSecretMissing = ::Util::TrackableErrorClass.new(
      msg: "Missing value for resource: {0-resource-name}",
      code: "CONJ00037E"
    )

    InsufficientPasswordComplexity = ::Util::TrackableErrorClass.new(
      msg: "The password you have chosen does not meet the complexity requirements. " \
          "Choose a password that includes: 12-128 characters, 2 uppercase letters, " \
          "2 lowercase letters, 1 digit and 1 special character",
      code: "CONJ00046E"
    )

    InvalidTrustedProxies = ::Util::TrackableErrorClass.new(
      msg: "Invalid IP address or CIDR address range in TRUSTED_PROXIES: {0-cidr}",
      code: "CONJ00065E"
    )

    BadSecretEncoding = ::Util::TrackableErrorClass.new(
      msg: "Issue encoding secret into JSON format, try including 'Accept-Encoding: base64' " \
          "header in request.",
      code: "CONJ00074E"
    )

    MissingSecretValue = ::Util::TrackableErrorClass.new(
      msg: "Variable {0-variable-id} is empty or not found.",
      code: "CONJ00076E"
    )
  end

  module Authentication

    AuthenticatorNotSupported = ::Util::TrackableErrorClass.new(
      msg: "Authenticator '{0-authenticator-name}' is not supported in Conjur",
      code: "CONJ00001E"
    )

    InvalidCredentials = ::Util::TrackableErrorClass.new(
      msg: "Invalid credentials",
      code: "CONJ00002E"
    )

    InvalidOrigin = ::Util::TrackableErrorClass.new(
      msg: "User is not authorized to login from the current origin",
      code: "CONJ00003E"
    )

    StatusNotSupported = ::Util::TrackableErrorClass.new(
      msg: "Status check not supported for authenticator '{0-authenticator-name}'",
      code: "CONJ00056E"
    )

    AdminAuthenticationDenied = ::Util::TrackableErrorClass.new(
      msg: "Admin user is not allowed to authenticate with {0-authenticate-name}",
      code: "CONJ00017E"
    )

    module AuthenticatorClass

      DoesntStartWithAuthn = ::Util::TrackableErrorClass.new(
        msg: "'{0-authenticator-parent-name}' is not a valid authenticator "\
            "parent module because it does not begin with 'Authn'",
        code: "CONJ00038E"
      )

      NotNamedAuthenticator = ::Util::TrackableErrorClass.new(
        msg: "'{0-authenticator-name}' is not a valid authenticator name. " \
            "The actual class implementing the authenticator must be named 'Authenticator'",
        code: "CONJ00039E"
      )

      MissingValidMethod = ::Util::TrackableErrorClass.new(
        msg: "'{0-authenticator-name}' is not a valid authenticator because " \
            "it does not have a `:valid?(input)` method.",
        code: "CONJ00040E"
      )

    end

    module Security

      AuthenticatorNotWhitelisted = ::Util::TrackableErrorClass.new(
        msg: "'{0-authenticator-name}' is not enabled",
        code: "CONJ00004E"
      )

      WebserviceNotFound = ::Util::TrackableErrorClass.new(
        msg: "Webservice '{0-webservice-name}' not found",
        code: "CONJ00005E"
      )

      RoleNotAuthorizedOnResource = ::Util::TrackableErrorClass.new(
        msg: "'{0-role-name}' does not have '{1-privilege}' privilege on {2-resource-name}",
        code: "CONJ00006E"
      )

      RoleNotFound = ::Util::TrackableErrorClass.new(
        msg: "'{0-role-name}' not found",
        code: "CONJ00007E"
      )

      AccountNotDefined = ::Util::TrackableErrorClass.new(
        msg: "Account '{0-account-name}' is not defined in Conjur",
        code: "CONJ00008E"
      )

    end

    module RequestBody

      MissingRequestParam = ::Util::TrackableErrorClass.new(
        msg: "Field '{0-field-name}' is missing or empty in request body",
        code: "CONJ00009E"
      )

    end

    module OAuth

      ProviderDiscoveryTimeout = ::Util::TrackableErrorClass.new(
        msg: "Failed to discover Identity Provider with timeout error (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00010E"
      )

      ProviderDiscoveryFailed = ::Util::TrackableErrorClass.new(
        msg: "Failed to discover Identity Provider (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00011E"
      )

      FetchProviderKeysFailed = ::Util::TrackableErrorClass.new(
        msg: "Failed to fetch keys from Identity Provider (Provider URI: '{0}'). Reason: '{1}'",
        code: "CONJ00012E"
      )

    end

    module Jwt

      TokenExpired = ::Util::TrackableErrorClass.new(
        msg: "Token expired",
        code: "CONJ00016E"
      )

      TokenDecodeFailed = ::Util::TrackableErrorClass.new(
        msg: "Failed to decode token (3rdPartyError ='{0}')",
        code: "CONJ00035E"
      )

      TokenVerificationFailed = ::Util::TrackableErrorClass.new(
        msg: "Failed to verify token (3rdPartyError ='{0}')",
        code: "CONJ00015E"
      )

      TokenClaimNotFoundOrEmpty = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-claim-name}' not found or empty in token",
        code: "CONJ00051E"
      )

      RequestBodyMissingJWTToken = ::Util::TrackableErrorClass.new(
        msg: "The request body does not contain JWT token",
        code: "CONJ00077E"
      )

    end

    module AuthnOidc

      IdTokenClaimNotFoundOrEmpty = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-claim-name}' not found or empty in ID token. " \
            "This claim is defined in the id-token-user-property variable.",
        code: "CONJ00013E"
      )

      ServiceIdMissing = ::Util::TrackableErrorClass.new(
        msg: "Service id is required when authenticating with authn-oidc",
        code: "CONJ00075E"
      )

    end

    module AuthnIam

      InvalidAWSHeaders = ::Util::TrackableErrorClass.new(
        msg: "Invalid or expired AWS headers: {0}",
        code: "CONJ00018E"
      )

      VerificationError = ::Util::TrackableLogMessageClass.new(
        msg: "Verification of IAM identity failed with exception: {0-exception}",
        code: "CONJ00063E"
      )

      IdentityVerificationErrorCode = ::Util::TrackableLogMessageClass.new(
        msg: "Verification of IAM identity failed with HTTP code: {0-http-code}",
        code: "CONJ00064E"
      )

    end

    module AuthnK8s

      CSRIsMissingSpiffeId = ::Util::TrackableErrorClass.new(
        msg: 'CSR must contain SPIFFE ID SAN',
        code: "CONJ00022E"
      )

      PodNotFound = ::Util::TrackableErrorClass.new(
        msg: "No pod found for '{0-pod-name}' in namespace '{1}'",
        code: "CONJ00024E"
      )

      K8sResourceNotFound = ::Util::TrackableErrorClass.new(
        msg: "Kubernetes {0-resource-name} {1-object-name} not found in namespace {2}",
        code: "CONJ00026E"
      )

      ContainerNotFound = ::Util::TrackableErrorClass.new(
        msg: "Container '{0}' was not found in the pod. Host id: {1}",
        code: "CONJ00028E"
      )

      MissingClientCertificate = ::Util::TrackableErrorClass.new(
        msg: "Client SSL certificate is missing from the header",
        code: "CONJ00029E"
      )

      UntrustedClientCertificate = ::Util::TrackableErrorClass.new(
        msg: "Client certificate cannot be verified by certification authority",
        code: "CONJ00030E"
      )

      CommonNameDoesntMatchHost = ::Util::TrackableErrorClass.new(
        msg: "Client certificate CN must match host name. Cert CN: {0}. " \
            "Host name: {1}.",
        code: "CONJ00031E"
      )

      ClientCertificateExpired = ::Util::TrackableErrorClass.new(
        msg: "Client certificate expired",
        code: "CONJ00032E"
      )

      ExecCommandTimedOut = ::Util::TrackableErrorClass.new(
        msg: "Exec command timed out after {0} seconds in container '{1}' of pod '{2}'",
        code: "CONJ00033E"
      )

      WebSocketHandshakeError = ::Util::TrackableErrorClass.new(
        msg: "WebSocket handshake failed with error {0}",
        code: "CONJ00071E"
      )

      ExecCommandError = ::Util::TrackableErrorClass.new(
        msg: "Exec command failed in container '{0}' of pod '{1}' with error {2}",
        code: "CONJ00072E"
      )

      UnexpectedChannel = ::Util::TrackableErrorClass.new(
        msg: "Unexpected channel: {0}",
        code: "CONJ00073E"
      )

      MissingServiceAccountDir = ::Util::TrackableErrorClass.new(
        msg: "Kubernetes serviceaccount dir '{0}' does not exist",
        code: "CONJ00034E"
      )

      UnknownK8sResourceType = ::Util::TrackableErrorClass.new(
        msg: "Unknown Kubernetes resource type '{0}'",
        code: "CONJ00041E"
      )

      InvalidApiUrl = ::Util::TrackableErrorClass.new(
        msg: "Received invalid Kubernetes API url: '{0}'",
        code: "CONJ00042E"
      )

      MissingCertificate = ::Util::TrackableErrorClass.new(
        msg: "No Kubernetes API certificate available",
        code: "CONJ00043E"
      )

      NamespaceMismatch = ::Util::TrackableErrorClass.new(
        msg: "Namespace in SPIFFE ID '{0-spiffe-namespace}' must match namespace " \
            "implied by resource restriction: '{1-resource-restrictions-namespace}'",
        code: "CONJ00023E"
      )

      CSRMissingCNEntry = ::Util::TrackableErrorClass.new(
        msg: "CSR [subject: '{0-subject}', spiffe_id: '{1-spiffe-id}'] must have a CN (common name) entry.",
        code: "CONJ00058E"
      )

      CertMissingCNEntry = ::Util::TrackableErrorClass.new(
        msg: "Cert [subject: '{0-subject}', san: '{1-san}'] must have a CN (common name) entry.",
        code: "CONJ00059E"
      )

      PodNameMismatchError = ::Util::TrackableErrorClass.new(
        msg: "Pod: {0-pod-name} does not match: {1-actual-resource-name}.",
        code: "CONJ00060E"
      )

      PodRelationMismatchError = ::Util::TrackableErrorClass.new(
        msg: "Pod: {0-pod-name}, {1-resource-type}: {2-expected-resource-name}, does not match: " \
                  "{3-actual-resource-name}.",
        code: "CONJ00061E"
      )

      PodMissingRelationError = ::Util::TrackableErrorClass.new(
        msg: "Pod: {0-pod-name} does not belong to a {1-resource-type}.",
        code: "CONJ00062E"
      )

      InvalidHostId = ::Util::TrackableErrorClass.new(
        msg: "Invalid Kubernetes host id: {0}. Must end with <namespace>/<resource_type>/<resource_id>",
        code: "CONJ00048E"
      )
    end

    module AuthnAzure

      XmsMiridParseError = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse xms_mirid {0}. Reason: {1}",
        code: "CONJ00052E"
      )

      MissingRequiredFieldsInXmsMirid = ::Util::TrackableErrorClass.new(
        msg: "Required fields {0} are missing in xms_mirid {1}",
        code: "CONJ00053E"
      )

      InvalidProviderFieldsInXmsMirid = ::Util::TrackableErrorClass.new(
        msg: "Provider fields are in invalid format in xms_mirid {1}. " \
                "xms_mirid must contain the resource provider namespace, the " \
                "resource type, and the resource name",
        code: "CONJ00054E"
      )
    end

    module AuthnGcp

      InvalidAudience = ::Util::TrackableErrorClass.new(
        msg: "'audience' token claim {0} is invalid. The format should be " \
              "'conjur/<account-name>/<host-id>'",
        code: "CONJ00067E"
      )

      JwtTokenClaimIsMissing = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-attribute-name}' is missing from Google's JWT token. " \
             "Verify that you configured the host with permitted restrictions. " \
             "In case of Compute Engine token, verify that you requested the token using 'format=full'",
        code: "CONJ00068E"
      )

      InvalidAccountInAudienceClaim = ::Util::TrackableErrorClass.new(
        msg: "'audience' token claim '{0}' is invalid. " \
              "The account in the audience '{1}' does not match the account in the URL request '{2}'",
        code: "CONJ00070E"
      )
    end

    module AuthnJwt

      InvalidIssuerConfiguration = ::Util::TrackableErrorClass.new(
        msg: "Issuer authenticator configuration is invalid. You should configured as authenticator variables: " \
              "'{0-resource-name}' or one of the following: '{1-resource-name}','{2-resource-name}'",
        code: "CONJ00078E"
      )

      FailedToParseHostnameFromUri = ::Util::TrackableErrorClass.new(
        msg: "Failed to extract hostname from URI '{0}'",
        code: "CONJ00079E"
      )

      InvalidUriFormat = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse URI '{0}'. Reason: '{1}'",
        code: "CONJ00080E"
      )

      NoSuchFieldInToken = ::Util::TrackableErrorClass.new(
        msg: "'{0}' field not found in the token",
        code: "CONJ00081E"
      )

      NoUsernameInTheURL = ::Util::TrackableErrorClass.new(
        msg: "No username in the URL",
        code: "CONJ00082E"
      )

      JwtTokenClaimIsMissing = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-attribute-name}' is missing from JWT token. " \
             "Verify that you configured the host with permitted restrictions.",
        code: "CONJ00084E"
      )

      MissingToken = ::Util::TrackableErrorClass.new(
        msg: "Token is empty or not found.",
        code: "CONJ00085E"
      )

      FetchJwksKeysFailed = ::Util::TrackableErrorClass.new(
        msg: "Failed to fetch JWKS from '{0-uri}'. Reason: '{1}'",
        code: "CONJ00087E"
      )

      FetchJwksUriKeysNotFound = ::Util::TrackableErrorClass.new(
        msg: "JWKS not found in response: '{0-encoded-response}'",
        code: "CONJ00088E"
      )

      UnsupportedClaim = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-claim}' does not support fetching the application identity",
        code: "CONJ00089E"
      )

      MissingClaimValue = ::Util::TrackableErrorClass.new(
        msg: "Claim '{0-claim}' value is empty, or was not found in token.",
        code: "CONJ00090E"
      )

      MissingMandatoryClaim = ::Util::TrackableErrorClass.new(
        msg: "Failed to validate token: mandatory claim '{0-claim}' is missing.",
        code: "CONJ00091E"
      )

      UnsupportedAuthenticator = ::Util::TrackableErrorClass.new(
        msg: "Authenticator '{0-authenticator-name}' is unsupported.",
        code: "CONJ00092E"
      )

      FailedToConvertResponseToJwks = ::Util::TrackableErrorClass.new(
        msg: "Failed to convert HTTP response '{0-encoded-response}' to JWKS type. Reason: '{1}'",
        code: "CONJ00093E"
      )

      MissingClaim = ::Util::TrackableErrorClass.new(
        msg: "Claim is empty or not found.",
        code: "CONJ00095E"
      )

      ServiceIdMissing = ::Util::TrackableErrorClass.new(
        msg: "Service ID is required when authenticating with authn-jwt",
        code: "CONJ00097E"
      )

      IdentityMisconfigured = ::Util::TrackableErrorClass.new(
        msg: "JWT identity configuration is invalid",
        code: "CONJ00098E"
      )

      MissingIdentity = ::Util::TrackableErrorClass.new(
        msg: "JWT identity is empty or was not found.",
        code: "CONJ00101E"
      )

      MissingIdentityPrefix = ::Util::TrackableErrorClass.new(
        msg: "JWT identity prefix is empty or was not found.",
        code: "CONJ00102E"
      )

      FailedToValidateClaimMissingClaimName = ::Util::TrackableErrorClass.new(
        msg: "Failed to validate claim: claim name is empty or was not found.",
        code: "CONJ00103E"
      )

      FailedToValidateClaimForbiddenClaimName = ::Util::TrackableErrorClass.new(
        msg: "Failed to validate claim: claim name '{0-claim-name}' does not " \
             "match regular expression: '{1-regex}'.",
        code: "CONJ00104E"
      )

      FailedToValidateClaimClaimNameInDenyList  = ::Util::TrackableErrorClass.new(
        msg: "Failed to validate claim: claim name '{0-claim-name}' is in denylist '{1-deny-list}'",
        code: "CONJ00105E"
      )

      FailedToParseEnforcedClaimsMissingInput = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse enforced claims: enforced claim value is empty or was not found.",
        code: "CONJ00106E"
      )

      InvalidEnforcedClaimsFormat = ::Util::TrackableErrorClass.new(
        msg: "List of enforced claims '{0-enforced-claims-value}' is in invalid format. " \
             "Separate claim names with commas.",
        code: "CONJ00107E"
      )

      InvalidEnforcedClaimsFormatContainsDuplication = ::Util::TrackableErrorClass.new(
        msg: "List of enforced claims '{0-enforced-claims-value}' must not contain duplications.",
        code: "CONJ00108E"
      )

      ClaimAliasesMissingInput = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: the claim aliases value is empty or was not found.",
        code: "CONJ00109E"
      )

      ClaimAliasesBlankOrEmpty = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: one or more mapping statements are blank or empty " \
             "'{0-claim-aliases-value}'.",
        code: "CONJ00110E"
      )

      ClaimAliasInvalidFormat = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: the claim alias value '{0-claim-alias-value}' is in invalid format."\
             "The correct format is: 'annotation_name:claim_name'",
        code: "CONJ00111E"
      )

      ClaimAliasInvalidClaimFormat = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: one of the claims in the claim alias value '{0-claim-alias-value}' " \
             "is in an invalid format : {1-claim-verification-error}.",
        code: "CONJ00112E"
      )

      ClaimAliasDuplicationError = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: {0-purpose} value '{1-claim-value}' appears more than once",
        code: "CONJ00113E"
      )

      ClaimAliasNameInvalidCharacter = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim aliases: the claim alias name '{0-claim-alias-name}' contains '/'.",
        code: "CONJ00114E"
      )

      RoleWithRegisteredOrClaimAliasError = ::Util::TrackableErrorClass.new(
        msg: "Role can't have registered or aliased claim. Error: '{0-error}'",
        code: "CONJ00069E"
      )

      AudienceValueIsEmpty = ::Util::TrackableErrorClass.new(
        msg: "Failed to fetch audience value: audience value is empty",
        code: "CONJ00115E"
      )

      InvalidClaimPath = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse claim path: '{0-claim-path}'. The claim path is in an invalid format. " \
             "The valid format should meet the following regex: '{1-claim-path-format}'",
        code: "CONJ00116E"
      )

      InvalidTokenAppPropertyValue = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse 'token-app-property' value. Error: '{0-error}'",
        code: "CONJ00117E"
      )

      TokenAppPropertyValueIsNotString = ::Util::TrackableErrorClass.new(
        msg: "'{0-claim-path}' value in token has type '{1-type}'. An identity must be a String.",
        code: "CONJ00118E"
      )

      InvalidRestrictionName = ::Util::TrackableErrorClass.new(
        msg: "Restriction '{0-restriction-name}' is invalid and not representing claim path in the token",
        code: "CONJ00119E"
      )

      InvalidPublicKeys = ::Util::TrackableErrorClass.new(
        msg: "Failed to parse 'public-keys': {0-parse-error}",
        code: "CONJ00120E"
      )

      InvalidSigningKeyType = ::Util::TrackableErrorClass.new(
        msg: "Signing key type '{0-type}' is invalid",
        code: "CONJ00121E"
      )

      InvalidSigningKeySettings = ::Util::TrackableErrorClass.new(
        msg: "Invalid signing key settings: {0-validation-error}",
        code: "CONJ00122E"
      )

      FailedToFetchJwksData = ::Util::TrackableErrorClass.new(
        msg: "Failed to fetch JWKS data from '{0-jwks-uri}' with error: {1-error}",
        code: "CONJ00123E"
      )
    end

    module ResourceRestrictions

      InvalidResourceRestrictions = ::Util::TrackableErrorClass.new(
        msg: "Resource restriction '{0-resource-restriction-name}' does not match " \
           "with the corresponding value in the request",
        code: "CONJ00049E"
      )

      EmptyAnnotationGiven = ::Util::TrackableErrorClass.new(
        msg: "Annotation, '{0-annotation-name}', is empty",
        code: "CONJ00100E"
      )

    end

    module Constraints

      ConstraintNotSupported = ::Util::TrackableErrorClass.new(
        msg: "Resource restrictions '{0}' are not supported. " \
             "The supported resources are '{1}'",
        code: "CONJ00050E"
      )

      IllegalConstraintCombinations = ::Util::TrackableErrorClass.new(
        msg: "Resource restrictions include an illegal combination of resource " \
             "constraints - '{0-constraints}'",
        code: "CONJ00055E"
      )

      RoleMissingConstraints = ::Util::TrackableErrorClass.new(
        msg: "Role does not have the required constraints: '{0-constraints}'",
        code: "CONJ00057E"
      )

      RoleMissingRequiredConstraints = ::Util::TrackableErrorClass.new(
        msg: "Role must have at least one of the following constraints: {0-constraints}",
        code: "CONJ00069E"
      )

      NonPermittedRestrictionGiven = ::Util::TrackableErrorClass.new(
        msg: "Role can't have one of these none permitted restrictions '{0-restrictions}'",
        code: "CONJ00069E"
      )

      RoleMissingAnyRestrictions =  ::Util::TrackableErrorClass.new(
        msg: "Role must have at least one relevant annotation",
        code: "CONJ00099E"
      )
    end
  end

  module Util

    ConcurrencyLimitReachedBeforeCacheInitialization = ::Util::TrackableErrorClass.new(
      msg: "Concurrency limited cache reached before cache initialized",
      code: "CONJ00044E"
    )
  end
end
