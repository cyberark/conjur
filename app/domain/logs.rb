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
        msg: "Retrieved value of annotation {0-annotation-name}",
        code: "CONJ00024D"
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
        code: "CONJ00039D"
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
        msg: "Fetching issuer authenticator configuration value",
        code: "CONJ00052D"
      )

      FetchedIssuerValueFromConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Fetched issuer value from authenticator configuration",
        code: "CONJ00053D"
      )

      IssuerResourceNameConfiguration = ::Util::TrackableLogMessageClass.new(
        msg: "Issuer value will be taken from '{0-resource-id}'",
        code: "CONJ00054D"
      )

      RetrievedIssuerValue = ::Util::TrackableLogMessageClass.new(
        msg: "Retrieved issuer with value '{0}'",
        code: "CONJ00055D"
      )

      ParsingIssuerFromUri = ::Util::TrackableLogMessageClass.new(
        msg: "Parsing issuer value from URI '{0}'",
        code: "CONJ00056D"
      )

      JWTAuthenticatorEntryPoint = ::Util::TrackableLogMessageClass.new(
        msg: "Entered jwt authentication flow for vendor '{0}'",
        code: "CONJ00057D"
      )

      URL_IDENTITY_PROVIDER_SELECTED = ::Util::TrackableLogMessageClass.new(
        msg: "JWT Identity in url is available and will be retrieved from it",
        code: "CONJ00058D"
      )

      DECODED_TOKEN_IDENTITY_PROVIDER_SELECTED = ::Util::TrackableLogMessageClass.new(
        msg: "JWT Identity in decoded token is available and will be retrieved from it",
        code: "CONJ00059D"
      )

      LOOKING_FOR_IDENTITY_FIELD_NAME = ::Util::TrackableLogMessageClass.new(
        msg: "Looking for variable field name in '{0}'",
        code: "CONJ00060D"
      )

      CHECKING_IDENTITY_FIELD_EXISTS = ::Util::TrackableLogMessageClass.new(
        msg: "Checking if the field exists",
        code: "CONJ00061D"
      )

      CREATING_AUTHENTICATION_PARAMETERS_OBJECT = ::Util::TrackableLogMessageClass.new(
        msg: "Creating authentication parameters objects",
        code: "CONJ00062D"
      )

      VALIDATE_AND_DECODE_TOKEN = ::Util::TrackableLogMessageClass.new(
        msg: "Validate and decode token",
        code: "CONJ00063D"
      )

      GET_JWT_IDENTITY = ::Util::TrackableLogMessageClass.new(
        msg: "Getting JWT Identity",
        code: "CONJ00064D"
      )

      CHECKING_IDENTITY_FIELD_EXISTS = ::Util::TrackableLogMessageClass.new(
        msg: "Checking if the field exists",
        code: "CONJ00065D"
      )

      JWT_AUTHENTICATION_PASSED = ::Util::TrackableLogMessageClass.new(
        msg: "JWT authentication passed successfully",
        code: "CONJ00066D"
      )
    end
  end

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

  end
end
