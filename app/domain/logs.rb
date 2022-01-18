# frozen_string_literal: true

module LogMessages

  module Conjur

    PrimarySchema = ::Util::TrackableLogMessageClass.new(
      msg: "Primary schema is {0-primary-schema}",
      code: "CONJ00034I"
    )

    FipsModeStatus = ::Util::TrackableLogMessageClass.new(
      msg: "OpenSSL FIPS mode set to {0}",
      code: "CONJ00038I"
    )

  end

  module Authentication

    LoginError = ::Util::TrackableErrorClass.new(
      msg: "Login Error: {0}",
      code: "CONJ00047I"
    )

    AuthenticationError = ::Util::TrackableErrorClass.new(
      msg: "Authentication Error: {0}",
      code: "CONJ00048I"
    )

    OriginValidated = ::Util::TrackableLogMessageClass.new(
      msg: "Origin validated",
      code: "CONJ00003D"
    )

    ContainerNameAnnotationDefaultValue = ::Util::TrackableLogMessageClass.new(
      msg: "Annotation '{0-authentication-container-annotation-name}' not found. " \
                "Using default value '{1-default-authentication-container}'",
      code: "CONJ00033D"
    )

    EncodedJWTResponse = ::Util::TrackableLogMessageClass.new(
      msg: "Responding with a base64 encoded access token",
      code: "CONJ00039D"
    )

    module OAuth

      IdentityProviderUri = ::Util::TrackableLogMessageClass.new(
        msg: "Working with Identity Provider {0-provider-uri}",
        code: "CONJ00007D"
      )

      IdentityProviderDiscoverySuccess = ::Util::TrackableLogMessageClass.new(
        msg: "Identity Provider discovery succeeded",
        code: "CONJ00008D"
      )

      FetchProviderKeysSuccess = ::Util::TrackableLogMessageClass.new(
        msg: "Fetched Identity Provider keys from provider successfully",
        code: "CONJ00009D"
      )

      IdentityProviderKeysFetchedFromCache = ::Util::TrackableLogMessageClass.new(
        msg: "Fetched Identity Provider keys from cache successfully",
        code: "CONJ00017D"
      )

      ValidateProviderKeysAreUpdated = ::Util::TrackableLogMessageClass.new(
        msg: "Validating that Identity Provider keys are up to date",
        code: "CONJ00019D"
      )

    end

    module Jwt

      TokenDecodeSuccess = ::Util::TrackableLogMessageClass.new(
        msg: "Token decoded successfully",
        code: "CONJ00005D"
      )

      TokenDecodeFailed = ::Util::TrackableLogMessageClass.new(
        msg: "Failed to decode the token with the error '{0-exception}'",
        code: "CONJ00018D"
      )

      ExtractedClaimFromToken = ::Util::TrackableLogMessageClass.new(
        msg: "Extracted claim '{0-claim-name}' with value {1-claim-value} from token",
        code: "CONJ00031D"
      )

      ExtractedUsernameFromToken = ::Util::TrackableLogMessageClass.new(
        msg: "Extracted username '{0}' from token",
        code: "CONJ00038D"
      )

      OptionalTokenClaimNotFoundOrEmpty  = ::Util::TrackableLogMessageClass.new(
        msg: "Optional claim '{0-claim-name}' not found or empty in token",
        code: "CONJ00047D"
      )

    end

    module ResourceRestrictions

      RetrievedAnnotationValue = ::Util::TrackableLogMessageClass.new(
        msg: "Retrieved value of annotation '{0-annotation-name}'",
        code: "CONJ00024I"
      )

      ValidatingResourceRestrictions = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restriction for role '{0-role-id}'",
        code: "CONJ00046D"
      )

      ValidatedResourceRestrictions = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions validated",
        code: "CONJ00030D"
      )

      ExtractingRestrictionsFromResource = ::Util::TrackableLogMessageClass.new(
        msg: "Extracting resource restrictions for authenticator '{0-authn-name}' from host '{1-host-name}'",
        code: "CONJ00032I"
      )

      ExtractedResourceRestrictions = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions were extracted: '{0-restrictions-names}'",
        code: "CONJ00040D"
      )

      ValidatingResourceRestrictionsConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restrictions configuration",
        code: "CONJ00041D"
      )

      ValidatedResourceRestrictionsConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions configuration validated",
        code: "CONJ00042D"
      )

      ValidatingResourceRestrictionsValues = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restrictions on request",
        code: "CONJ00044D"
      )

      ValidatingResourceRestrictionOnRequest = ::Util::TrackableLogMessageClass.new(
        msg: "Validating resource restriction on request: '{0-restriction-name}'",
        code: "CONJ00048D"
      )

      ValidatedResourceRestrictionsValues = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions matched request",
        code: "CONJ00045D"
      )

      ValidatingRestrictionConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Validating restriction configuration...",
        code: "CONJ00143D"
      )

      ValidatedRestrictionConfigurationSuccessfully = ::Util::TrackableLogMessageClass.new(
        msg: "Restriction configuration validated successfully",
        code: "CONJ00144D"
      )

    end

    module AuthnOidc

      ExtractedUsernameFromIDToken = ::Util::TrackableLogMessageClass.new(
        msg: "Extracted username '{0}' from ID token claim '{1-id-token-username-claim}'",
        code: "CONJ00004D"
      )

    end

    module AuthnK8s

      PodChannelOpen = ::Util::TrackableLogMessageClass.new(
        msg: "Pod '{0-pod-name}' : channel open",
        code: "CONJ00010D"
      )

      PodChannelClosed = ::Util::TrackableLogMessageClass.new(
        msg: "Pod '{0-pod-name}' : channel closed",
        code: "CONJ00011D"
      )

      PodChannelData = ::Util::TrackableLogMessageClass.new(
        msg: "Pod '{0-pod-name}', channel '{1-cahnnel-name}': {2-message-data}",
        code: "CONJ00012D"
      )

      PodMessageData = ::Util::TrackableLogMessageClass.new(
        msg: "Pod '{0-pod-name}': message: '{1-message-type}', data: '{2-message-data}'",
        code: "CONJ00013D"
      )

      PodError = ::Util::TrackableLogMessageClass.new(
        msg: "Pod '{0-pod-name}' error : '{1}'",
        code: "CONJ00014D"
      )

      CopySSLToPod = ::Util::TrackableLogMessageClass.new(
        msg: "Copying client certificate to {0-container-name}:{1-cert-file-path} " \
            "in {2-pod-namespace}/{3-pod-name}",
        code: "CONJ00015D"
      )

      InitializeCopySSLToPodSuccess = ::Util::TrackableLogMessageClass.new(
        msg: "Started copying the client certificate successfully",
        code: "CONJ00037D"
      )

      HostIdFromCommonName = ::Util::TrackableLogMessageClass.new(
        msg: "Host id {0} extracted from CSR common name",
        code: "CONJ00027D"
      )

      SetCommonName = ::Util::TrackableLogMessageClass.new(
        msg: "Setting common name to {0-full-host-name}",
        code: "CONJ00028D"
      )

      InvalidTimeout = ::Util::TrackableLogMessageClass.new(
        msg: "'{0}' is not a valid timeout. Using default: {1}.",
        code: "CONJ00047W"
      )

      ExtractingRestrictionsFromHostId = ::Util::TrackableLogMessageClass.new(
        msg: "Resource restrictions were not found in annotations, extracting from host ID '{0-host-name}'",
        code: "CONJ00049D"
      )

      ValidatingK8sResource = ::Util::TrackableLogMessageClass.new(
        msg: "Validating K8s resource. Type:'{0}', Name: {1}",
        code: "CONJ00050D"
      )

      ValidatedK8sResource = ::Util::TrackableLogMessageClass.new(
        msg: "Validated K8s resource. Type:'{0}', Name: {1}",
        code: "CONJ00051D"
      )
    end

    module AuthnIam

      GetCallerIdentityBody = ::Util::TrackableLogMessageClass.new(
        msg: "AWS IAM get_caller_identity body:\n {0-response-body}",
        code: "CONJ00034D"
      )

      AttemptToMatchHost = ::Util::TrackableLogMessageClass.new(
        msg: "IAM Role authentication attempt by AWS user {0-aws-user-id} " \
                  "with host to match = {1-host-to-match}",
        code: "CONJ00035D"
      )

      RetrieveIamIdentity = ::Util::TrackableLogMessageClass.new(
        msg: "Retrieving IAM identity",
        code: "CONJ00036D"
      )

    end

    module AuthnAzure

      ExtractedResourceRestrictionsFromToken = ::Util::TrackableLogMessageClass.new(
        msg: "Extracted resource restrictions from token",
        code: "CONJ00029D"
      )

    end

    module AuthnJwt

      FetchingIssuerConfigurationValue = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching \"issuer\" value from authenticator configuration...",
        code: "CONJ00052D"
      )

      FetchedIssuerValueFromConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Fetched \"issuer\" value from authenticator configuration",
        code: "CONJ00053D"
      )

      IssuerResourceNameConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "\"issuer\" value will be taken from '{0-resource-id}'",
        code: "CONJ00054I"
      )

      RetrievedIssuerValue = ::Util::TrackableLogMessageClass.new(
        msg: "Retrieved \"issuer\" with value '{0}'",
        code: "CONJ00055I"
      )

      ParsingIssuerFromUri = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing \"issuer\" value from '{0}'...",
        code: "CONJ00056D"
      )

      JwtAuthenticatorEntryPoint = ::Util::TrackableLogMessageClass.new(
        msg: "Started authentication flow for authenticator '{0-authenticator-name}'",
        code: "CONJ00057I"
      )

      SelectingIdentityProviderInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Selecting identity provider interface...",
        code: "CONJ00058D"
      )

      SelectedIdentityProviderInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Selected identity provider interface: '{0-identity-provider-interface-name}'",
        code: "CONJ00059I"
      )

      RetrievedResourceValue = ::Util::TrackableLogMessageClass.new(
        msg: "Retrieved value '{0-resource-value}' of resource name '{1-resource-name}'",
        code: "CONJ00060I"
      )

      CheckingIdentityFieldExists = ::Util::TrackableLogMessageClass.new(
        msg: "Checking if field '{0}' is in the token...",
        code: "CONJ00061D"
      )

      CreatingJWTAuthenticationInputObject = ::Util::TrackableLogMessageClass.new(
        msg: "Creating JWT authenticator input object...",
        code: "CONJ00062D"
      )

      CallingValidateAndDecodeToken = ::Util::TrackableLogMessageClass.new(
        msg: "Calling 'validate_and_decode_token'...",
        code: "CONJ00063D"
      )

      CallingGetJwtIdentity = ::Util::TrackableLogMessageClass.new(
        msg: "Calling 'get_jwt_identity'...",
        code: "CONJ00064D"
      )

      CallingValidateRestrictions = ::Util::TrackableLogMessageClass.new(
        msg: "Calling 'validate_restrictions'...",
        code: "CONJ00065D"
      )

      JwtAuthenticationPassed = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully authenticated JWT",
        code: "CONJ00066D"
      )

      FetchingJwtClaimsToValidate = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching JWT claims to validate",
        code: "CONJ00067D"
      )

      FetchedJwtClaimsToValidate = ::Util::TrackableLogMessageClass.new(
        msg: "Fetched JWT claims '{0-claims-list}' to validate",
        code: "CONJ00068I"
      )

      AddingJwtClaimToValidate = ::Util::TrackableLogMessageClass.new(
        msg: "Adding JWT claim '{0-claim-name}' to list of mandatory claims to be validated...",
        code: "CONJ00069D"
      )

      CheckingJwtClaimToValidate = ::Util::TrackableLogMessageClass.new(
        msg: "Checking if JWT claim '{0-claim-name}' must be validated...",
        code: "CONJ00070D"
      )

      FetchingJwtConfigurationValue = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching '{0-resource-id}' resource definition from configuration...",
        code: "CONJ00071D"
      )

      FetchingJwksFromProvider = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching JWKS from '{0-uri}'...",
        code: "CONJ00072I"
      )

      FetchJwtUriKeysSuccess = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched JWKS",
        code: "CONJ00073D"
      )

      ValidatingJwtSigningKeyConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Validating signing key URI configuration...",
        code: "CONJ00074D"
      )

      SelectingSigningKeyInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Selecting signing key interface...",
        code: "CONJ00075D"
      )

      SelectedSigningKeyInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Selected signing key interface: '{0-signing-key-interface-name}'",
        code: "CONJ00076I"
      )

      ConvertingJwtClaimToVerificationOption = ::Util::TrackableLogMessageClass.new(
        msg: "Converting JWT claim '{0-claim-name}' to verification option",
        code: "CONJ00077D"
      )

      ConvertedJwtClaimToVerificationOption = ::Util::TrackableLogMessageClass.new(
        msg: "Converted JWT claim '{0-claim-name}' to verification option '{1-verification-option}'",
        code: "CONJ00078D"
      )

      ValidateSigningKeysAreUpdated = ::Util::TrackableLogMessageClass.new(
        msg: "Validating that signing keys are up to date",
        code: "CONJ00079D"
      )

      SigningKeysFetchedFromCache = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched signing keys from cache",
        code: "CONJ00080D"
      )

      ValidatingToken = ::Util::TrackableLogMessageClass.new(
        msg: "Validating token",
        code: "CONJ00081D"
      )

      ValidatedToken = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated token",
        code: "CONJ00082D"
      )

      ValidatingTokenSignature = ::Util::TrackableLogMessageClass.new(
        msg: "Validating token signature",
        code: "CONJ00083D"
      )

      ValidatedTokenSignature = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated token signature",
        code: "CONJ00084D"
      )

      ValidatingTokenClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Validating token claims...",
        code: "CONJ00085D"
      )

      ValidatedTokenClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated token claims",
        code: "CONJ00086D"
      )

      CreatingJwksFromHttpResponse = ::Util::TrackableLogMessageClass.new(
        msg: "Creating JWKS from HTTP response...",
        code: "CONJ00087D"
      )

      CreatedJwks = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully created JWKS",
        code: "CONJ00088D"
      )

      ValidatedIdentityConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated identity configuration",
        code: "CONJ00089D"
      )

      ValidatingJwtStatusConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Validating JWT status configuration...",
        code: "CONJ00090I"
      )

      ValidatedUserHasAccessToStatusWebservice = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated user has access to status webservice",
        code: "CONJ00091D"
      )

      ValidatedAuthenticatorWebServiceExists = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated status webservice exists",
        code: "CONJ00092D"
      )

      ValidatedStatusWebserviceIsWhitelisted = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated status webservice is allowlisted",
        code: "CONJ00093D"
      )

      ValidatedServiceIdExists = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated that service ID exists",
        code: "CONJ00094D"
      )

      ValidatedSigningKeyConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated signing key configuration",
        code: "CONJ00095D"
      )

      ValidatedIssuerConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated issuer configuration",
        code: "CONJ00096D"
      )

      FoundJwtFieldInToken = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully found field '{0}' in token and its value is '{1}'",
        code: "CONJ00097D"
      )

      FoundJwtIdentity= ::Util::TrackableLogMessageClass.new(
        msg: "Successfully found JWT identity '{0}'",
        code: "CONJ00098I"
      )

      ValidatedJwtStatusConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated JWT status configuration",
        code: "CONJ00099I"
      )

      ValidatedAccountExists = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated that account exists",
        code: "CONJ00100D"
      )

      ValidateAndDecodeTokenPassed = ::Util::TrackableLogMessageClass.new(
        msg: "'validate_and_decode_token' passed successfully",
        code: "CONJ00101D"
      )

      GetJwtIdentityPassed = ::Util::TrackableLogMessageClass.new(
        msg: "'get_jwt_identity' passed successfully",
        code: "CONJ00102D"
      )

      ValidateRestrictionsPassed = ::Util::TrackableLogMessageClass.new(
        msg: "'validate_restrictions' passed successfully",
        code: "CONJ00103D"
      )

      CreateValidateAndDecodeTokenInstance = ::Util::TrackableLogMessageClass.new(
        msg: "Creating token validator (validate_and_decode_token) instance...",
        code: "CONJ00104D"
      )

      CreatedValidateAndDecodeTokenInstance = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully created token validator (validate_and_decode_token) instance",
        code: "CONJ00105D"
      )

      CreateJwtRestrictionsValidatorInstance = ::Util::TrackableLogMessageClass.new(
        msg: "Creating JWT restrictions validator (validate_restrictions) instance...",
        code: "CONJ00108I"
      )

      CreatedJwtRestrictionsValidatorInstance = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully created JWT restrictions validator (validate_restrictions) instance",
        code: "CONJ00109I"
      )

      FetchingIdentityPath = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching identity path...",
        code: "CONJ00110D"
      )

      FetchedIdentityPath = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched JWT identity path '{0-identity-path}'",
        code: "CONJ00111I"
      )

      FetchingIdentityByInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching JWT identity by interface: '{0-interface-name}'...",
        code: "CONJ00112D"
      )

      FetchedIdentityByInterface = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched identity '{0-identity}' by interface: '{1-interface-name}'",
        code: "CONJ00113I"
      )

      AddingIdentityPrefixToIdentity = ::Util::TrackableLogMessageClass.new(
        msg: "Adding identity prefix '{0-identity-prefix}' to identity '{1-identity}'...",
        code: "CONJ00114D"
      )

      AddedIdentityPrefixToIdentity = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully added JWT identity prefix. Calculated identity is: '{0-identity}'",
        code: "CONJ00115D"
      )

      IdentityPathNotConfigured = ::Util::TrackableLogMessageClass.new(
        msg: "JWT identity path '{0-resource-name}' not configured. JWT identity will be taken from root policy",
        code: "CONJ00116D"
      )

      ClaimsDenyListValue = ::Util::TrackableLogMessageClass.new(
        msg: "The following claims are in denylist '{0-deny-claims-list}'",
        code: "CONJ00117D"
      )

      ValidatingClaimName = ::Util::TrackableLogMessageClass.new(
        msg: "Validating claim name '{0-claim-name}'...",
        code: "CONJ00118D"
      )

      ValidatedClaimName = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated claim name '{0-claim-name}'",
        code: "CONJ00119D"
      )

      ParsingEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing enforced claims '{0-enforced-claims}'...",
        code: "CONJ00120D"
      )

      ParsedEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully parsed enforced claims '{0-enforced-claims-list}'",
        code: "CONJ00121D"
      )

      FetchingEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching enforced claims...",
        code: "CONJ00122D"
      )

      NotConfiguredEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "No enforced claims configured",
        code: "CONJ00123D"
      )

      FetchedEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched enforced claims '{0-enforced-claims}'",
        code: "CONJ00124I"
      )

      ParsingClaimAliases = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing claim aliases '{0-claim-aliases}'...",
        code: "CONJ00125D"
      )
      ParsedClaimAliases = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully parsed claim aliases '{0-claim-aliases-table}'",
        code: "CONJ00126D"
      )

      ClaimMapDefinition = ::Util::TrackableLogMessageClass.new(
        msg: "Mapping annotation '{0-annotation-value}' to claim '{1-claim-name}'...",
        code: "CONJ00127D"
      )

      FetchingClaimAliases = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching claim aliases...",
        code: "CONJ00128D"
      )

      NotConfiguredClaimAliases = ::Util::TrackableLogMessageClass.new(
        msg: "No claim aliases configured",
        code: "CONJ00129D"
      )

      FetchedClaimAliases = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched claim aliases '{0-claim-aliases}'",
        code: "CONJ00130I"
      )

      CreateContraintsFromPolicy = ::Util::TrackableLogMessageClass.new(
        msg: "Creating constraints from policy...",
        code: "CONJ00131I"
      )

      CreatedConstraintsFromPolicy = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully created constraints from policy",
        code: "CONJ00132I"
      )

      ConvertingClaimAccordingToAlias = ::Util::TrackableLogMessageClass.new(
        msg: "Converting claim '{0-claim-name}' to annotation '{1-annotation-name}'...",
        code: "CONJ00133D"
      )

      ConstraintsFromEnforcedClaims = ::Util::TrackableLogMessageClass.new(
        msg: "Creating constraints from enforced claims: '{0-enforced-claims}'...",
        code: "CONJ00134D"
      )

      ValidatedEnforcedClaimsConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated the configured enforced claims",
        code: "CONJ00135D"
      )

      ValidatedClaimAliasesConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated the configured claim aliases",
        code: "CONJ00136D"
      )

      ClaimMapUsage = ::Util::TrackableLogMessageClass.new(
        msg: "Checking restriction '{0-annotation-value}', fetching value from '{1-claim-name}' claim...",
        code: "CONJ00137D"
      )

      FetchingAudienceValue = ::Util::TrackableLogMessageClass.new(
        msg: "Fetching audience value...",
        code: "CONJ00138D"
      )

      FetchedAudienceValue = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully fetched audience value '{0-value}'",
        code: "CONJ00139I"
      )

      ValidatedAudienceConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully validated audience configuration",
        code: "CONJ00140D"
      )

      ClaimPathParsingStart = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing claim path: '{0-claim-path}'",
        code: "CONJ00141D"
      )

      ClaimPathParsingEnd = ::Util::TrackableLogMessageClass.new(
        msg: "Claim path has been parsed: '{0-claim-path-array}'",
        code: "CONJ00142D"
      )

      ParsingStaticSigningKeys = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing JWKS from public-keys value...",
        code: "CONJ00143I"
      )

      ParsedStaticSigningKeys = ::Util::TrackableLogMessageClass.new(
        msg: "Successfully parsed public-keys value",
        code: "CONJ00144D"
      )
    end
  end

  # This are log messages so its okay there are many
  # :reek:TooManyConstants
  module Util

    RateLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
      msg: "Rate limited cache updated successfully",
      code: "CONJ00016D"
    )

    RateLimitedCacheLimitReached = ::Util::TrackableLogMessageClass.new(
      msg: "Rate limited cache reached the '{0-limit}' limit and will not " \
              "call target for the next '{1-seconds}' seconds",
      code: "CONJ00020D"
    )

    ConcurrencyLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
      msg: "Concurrency limited cache updated successfully",
      code: "CONJ00021D"
    )

    ConcurrencyLimitedCacheReached = ::Util::TrackableLogMessageClass.new(
      msg: "Concurrency limited cache reached the '{0-limit}' limit and will not call target",
      code: "CONJ00022D"
    )

    ConcurrencyLimitedCacheConcurrentRequestsUpdated = ::Util::TrackableLogMessageClass.new(
      msg: "Concurrency limited cache concurrent requests updated to '{0-concurrent-requests}'",
      code: "CONJ00023D"
    )

    ConcurrencyLimitedCacheKeyRetrieved = ::Util::TrackableLogMessageClass.new(
      msg: "ConcurrencyLimitedCache retrieved cache key : '{0-cache-key}'",
      code: "CONJ00024D"
    )

    RateLimitedCacheKeyRetrieved = ::Util::TrackableLogMessageClass.new(
      msg: "RateLimitedCache Retrieved cache key : '{0-cache-key}'",
      code: "CONJ00025D"
    )

    CheckingResourceExists = ::Util::TrackableLogMessageClass.new(
      msg: "Checking resource '{0-resource-id}' exists...",
      code: "CONJ00026D"
    )

  end
end
