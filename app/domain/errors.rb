# frozen_string_literal: true

require 'util/trackable_error_class'

unless defined? Errors::Authentication::AuthenticatorNotFound
  # This wrapper prevents classes from being loaded by Rails
  # auto-load. #TODO: fix this in a proper manner

  module Errors
    module Conjur

      RequiredResourceMissing = Util::TrackableErrorClass.new(
        msg: "Missing required resource: {0-resource-name}",
        code: "CONJ00036E"
      )

      RequiredSecretMissing = Util::TrackableErrorClass.new(
        msg: "Missing value for resource: {0-resource-name}",
        code: "CONJ00037E"
      )

    end

    module Authentication

      AuthenticatorNotFound = ::Util::TrackableErrorClass.new(
        msg: "Authenticator '{0-authenticator-name}' is not implemented in Conjur",
        code: "CONJ00001E"
      )

      InvalidCredentials = ::Util::TrackableErrorClass.new(
        msg: "Invalid credentials",
        code: "CONJ00002E"
      )

      InvalidOrigin = ::Util::TrackableErrorClass.new(
        msg: "Invalid origin",
        code: "CONJ00003E"
      )

      StatusNotImplemented = ::Util::TrackableErrorClass.new(
        msg: "Status check not implemented for authenticator '{0-authenticator-name}'",
        code: "CONJ00045E"
      )

      module AuthenticatorClass

        DoesntStartWithAuthn = ::Util::TrackableErrorClass.new(
          msg: "'{0-authenticator-parent-name}' is not a valid authenticator parent module because it does " \
            "not begin with 'Authn'",
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

        NotWhitelisted = ::Util::TrackableErrorClass.new(
          msg: "'{0-authenticator-name}' is not whitelisted in CONJUR_AUTHENTICATORS",
          code: "CONJ00004E"
        )

        ServiceNotDefined = ::Util::TrackableErrorClass.new(
          msg: "Webservice '{0-webservice-name}' is not defined in the Conjur policy",
          code: "CONJ00005E"
        )

        UserNotAuthorizedInConjur = ::Util::TrackableErrorClass.new(
          msg: "User '{0-user-name}' is not authorized in the Conjur policy",
          code: "CONJ00006E"
        )

        UserNotDefinedInConjur = ::Util::TrackableErrorClass.new(
          msg: "User '{0-user-name}' is not defined in Conjur",
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

      module AuthnOidc

        ProviderDiscoveryTimeout = ::Util::TrackableErrorClass.new(
          msg: "OIDC Provider discovery failed with timeout error (Provider URI: '{0}'). Reason: '{1}'",
          code: "CONJ00010E"
        )

        ProviderDiscoveryFailed = ::Util::TrackableErrorClass.new(
          msg: "OIDC Provider discovery failed (Provider URI: '{0}'). Reason: '{1}'",
          code: "CONJ00011E"
        )

        ProviderFetchCertificateFailed = ::Util::TrackableErrorClass.new(
          msg: "Failed to fetch certificate from OIDC Provider (Provider URI: '{0}'). Reason: '{1}'",
          code: "CONJ00012E"
        )

        IdTokenFieldNotFoundOrEmpty = ::Util::TrackableErrorClass.new(
          msg: "Field '{0-field-name}' not found or empty in ID Token. This field is defined in the id-token-user-property variable.",
          code: "CONJ00013E"
        )

        IdTokenInvalidFormat = ::Util::TrackableErrorClass.new(
          msg: "Invalid ID Token format (3rdPartyError ='{0}')",
          code: "CONJ00014E"
        )

        IdTokenVerifyFailed = ::Util::TrackableErrorClass.new(
          msg: "ID Token verification failed (3rdPartyError ='{0}')",
          code: "CONJ00015E"
        )

        IdTokenExpired = ::Util::TrackableErrorClass.new(
          msg: "ID Token expired",
          code: "CONJ00016E"
        )

        AdminAuthenticationDenied = ::Util::TrackableErrorClass.new(
          msg: "admin user is not allowed to authenticate with OIDC",
          code: "CONJ00017E"
        )

      end

      module AuthnIam

        InvalidAWSHeaders = ::Util::TrackableErrorClass.new(
          msg: "'Invalid or expired AWS headers: {0}",
          code: "CONJ00018E"
        )

      end

      module AuthnJenkins

        InvalidJenkinsCred = ::Util::TrackableErrorClass.new(
          msg: "'Invalid Jenkins Cred: {0}",
          code: "CONJ00045E"
        )

        HostNotFound=::Util::TrackableErrorClass.new(
          msg: "Host '{0}' wasn't found'",
          code: "CONJ00046E"
        )

        RunningJobNotFound=::Util::TrackableErrorClass.new(
          msg: "Job '{0}' is not running and cannot be authenticated",
          code: "CONJ00047E"
        )
        
        InvalidSignature=::Util::TrackableErrorClass.new(
          msg: "Invalid signature provided by jenkins. Data tampered or private-public key mismatch",
          code: "CONJ00048E"
        )

        BuildInfoError=::Util::TrackableErrorClass.new(
          msg: "Failed to retrieve build info from. Recieved {0}",
          code: "CONJ00049E"
        )

        InvalidURL=::Util::TrackableErrorClass.new(
          msg: "Invalid URL '{0}' http is not allowed unless the webservice annotation 'allow-http' is set to 'true'",
          code: "CONJ00050E"
        )

      end

      module AuthnK8s

        WebserviceNotFound = ::Util::TrackableErrorClass.new(
          msg: "Webservice '{0-webservice-name}' wasn't found",
          code: "CONJ00019E"
        )

        HostNotFound = ::Util::TrackableErrorClass.new(
          msg: "Host '{0-host-name}' wasn't found",
          code: "CONJ00020E"
        )

        HostNotAuthorized = ::Util::TrackableErrorClass.new(
          msg: "'{0-hostname}' does not have 'authenticate' privilege on {1-service-name}",
          code: "CONJ00021E"
        )

        CSRIsMissingSpiffeId = ::Util::TrackableErrorClass.new(
          msg: 'CSR must contain SPIFFE ID SAN',
          code: "CONJ00022E"
        )

        CSRNamespaceMismatch = ::Util::TrackableErrorClass.new(
          msg: "Namespace in SPIFFE ID '{0-cn-namespace}' must match namespace " \
            "implied by common name '{1-spiffe-namespace}'",
          code: "CONJ00023E"
        )

        PodNotFound = ::Util::TrackableErrorClass.new(
          msg: "No pod found for '{0-pod-name}' in namespace '{1}'",
          code: "CONJ00024E"
        )

        ScopeNotSupported = ::Util::TrackableErrorClass.new(
          msg: "Resource type '{0}' identity scope is not supported in this version " \
            "of authn-k8s",
          code: "CONJ00025E"
        )

        ControllerNotFound = ::Util::TrackableErrorClass.new(
          msg: "Kubernetes {0-controller-name} {1-object-name} not found in namespace {2}",
          code: "CONJ00026E"
        )

        CertInstallationError = ::Util::TrackableErrorClass.new(
          msg: "Certificate could not be copied to pod: {0}",
          code: "CONJ00027E"
        )

        ContainerNotFound = ::Util::TrackableErrorClass.new(
          msg: "Container {0} was not found for requesting pod",
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
            "Host name: {1}. ",
          code: "CONJ00031E"
        )

        ClientCertificateExpired = ::Util::TrackableErrorClass.new(
          msg: "Client certificate expired",
          code: "CONJ00032E"
        )

        CommandTimedOut = ::Util::TrackableErrorClass.new(
          msg: "Command timed out in container '{0}' of pod '{1}'",
          code: "CONJ00033E"
        )

        MissingServiceAccountDir = ::Util::TrackableErrorClass.new(
          msg: "Kubernetes serviceaccount dir '{0}' does not exist",
          code: "CONJ00034E"
        )

        MissingEnvVar = ::Util::TrackableErrorClass.new(
          msg: "Expected ENV variable '{0}' is not set",
          code: "CONJ00035E"
        )

        UnknownControllerType = ::Util::TrackableErrorClass.new(
          msg: "Unknown Kubernetes controller type '{0}'",
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
      end
    end

    module Util

      ConcurrencyLimitReachedBeforeCacheInitialization = ::Util::TrackableErrorClass.new(
        msg: "Concurrency limited cache reached before cache initialized",
        code: "CONJ00044E"
      )
    end
  end
end
