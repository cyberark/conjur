#require_relative 'host'
require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    Err = Errors::Authentication::AuthnK8s
    SecurityErr = Errors::Authentication::Security
    # Possible Errors Raised:
    # WebserviceNotFound, RoleNotAuthorizedOnWebservice, PodNotFound
    # ContainerNotFound, ScopeNotSupported, K8sResourceNotFound

    ValidatePodRequest ||= CommandClass.new(
      dependencies: {
        resource_class:                Resource,
        k8s_object_lookup_class:       K8sObjectLookup,
        validate_application_identity: ValidateApplicationIdentity.new
      },
      inputs:       %i(pod_request)
    ) do

      extend Forwardable
      def_delegators :@pod_request, :service_id, :k8s_host, :spiffe_id

      def call
        validate_webservice_exists
        validate_host_can_access_service
        validate_pod_exists
        validate_application_identity
      end

      private

      def validate_webservice_exists
        raise SecurityErr::WebserviceNotFound, service_id unless webservice.resource
      end

      def validate_host_can_access_service
        return if host_can_access_service?
        raise SecurityErr::RoleNotAuthorizedOnWebservice.new(host.role.id, "authenticate", service_id)
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

      def host_can_access_service?
        host.role.allowed_to?("authenticate", webservice.resource)
      end

      def host
        @host ||= @resource_class[k8s_host.conjur_host_id]
        raise SecurityErr::RoleNotFound(k8s_host.conjur_host_id) if @host.nil?
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
