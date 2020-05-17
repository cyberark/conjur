#require_relative 'host'
require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    Err = Errors::Authentication::AuthnK8s
    SecurityErr = Errors::Authentication::Security
    # Possible Errors Raised:
    # WebserviceNotFound, RoleNotAuthorizedOnResource, PodNotFound
    # ContainerNotFound, ScopeNotSupported, K8sResourceNotFound

    ValidatePodRequest ||= CommandClass.new(
      dependencies: {
        resource_class:                Resource,
        k8s_object_lookup_class:       K8sObjectLookup,
        validate_security:             ::Authentication::Security::ValidateSecurity.new,
        enabled_authenticators:        Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        validate_application_identity: ValidateApplicationIdentity.new
      },
      inputs:       %i(pod_request)
    ) do

      extend Forwardable
      def_delegators :@pod_request, :service_id, :k8s_host, :spiffe_id

      def call
        validate_security
        validate_pod_exists
        validate_application_identity
      end

      private

      def validate_security
        @validate_security.(
          webservice: webservice,
          account: k8s_host.account,
          user_id: k8s_host.k8s_host_name,
          enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_pod_exists
        raise Err::PodNotFound.new(pod_name, pod_namespace) unless pod
      end

      def validate_application_identity
        @validate_application_identity.(
          host_id: k8s_host.conjur_host_id,
          host_annotations: host.annotations,
          service_id: service_id,
          account: k8s_host.account,
          spiffe_id: spiffe_id
        )
      end

      # @return The Conjur resource for the webservice.
      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            k8s_host.account,
          authenticator_name: 'authn-k8s',
          service_id:         service_id
        )
      end

      def k8s_object_lookup
        @k8s_object_lookup ||= @k8s_object_lookup_class.new(webservice)
      end

      def host
        return @host if @host

        @host = @resource_class[k8s_host.conjur_host_id]
        raise SecurityErr::RoleNotFound(k8s_host.conjur_host_id) unless @host
        @host
      end

      def pod
        @pod ||= k8s_object_lookup.pod_by_name(pod_name, pod_namespace)
      end

      def pod_name
        spiffe_id.name
      end

      def pod_namespace
        spiffe_id.namespace
      end
    end
  end
end
