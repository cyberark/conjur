module Authentication
  module AuthnK8s

    AuthenticatorNotFound = ::Util::ErrorClass.new(
      "'{0}' wasn't in the available authenticators"
    )
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
      'Namespace in SPIFFE ID must match namespace implied by common name'
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
  end
end
