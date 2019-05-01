#require_relative 'host'
require 'forwardable'
require 'command_class'
require 'errors'

module Authentication
  module AuthnK8s

    # Possible Errors Raised:
    # WebserviceNotFound, HostNotAuthorized, PodNotFound
    # ContainerNotFound, ScopeNotSupported, ControllerNotFound

    ValidatePodRequest = CommandClass.new(
      dependencies: {
        resource_repo: Resource,
        k8s_resolver: K8sResolver
      },
      inputs: %i(pod_request)
    ) do

      extend Forwardable
      def_delegators :@pod_request, :service_id, :k8s_host, :spiffe_id

      def call
        validate_webservice_exists
        validate_host_can_access_service
        validate_pod_exists
        validate_pod_properties
        validate_container
      end

      private

      def validate_webservice_exists
        raise Errors::Authentication::AuthnK8s::WebserviceNotFound, service_id unless webservice.resource
      end

      def validate_host_can_access_service
        return if host_can_access_service?
        raise Errors::Authentication::AuthnK8s::HostNotAuthorized.new(host.role.id, service_id)
      end

      def validate_pod_exists
        raise Errors::Authentication::AuthnK8s::PodNotFound.new(pod_name, pod_namespace) unless pod
      end

      def validate_pod_properties
        return if k8s_host.namespace_scoped?
        validate_scope
        validate_controller
        validate_pod_metadata
      end

      def validate_container
        raise Errors::Authentication::AuthnK8s::ContainerNotFound, container_name unless container
      end

      def validate_scope
        return if k8s_host.permitted_scope?
        raise Errors::Authentication::AuthnK8s::ScopeNotSupported, k8s_host.controller
      end

      def validate_controller
        return if controller_object
        raise Errors::Authentication::AuthnK8s::ControllerNotFound.new(k8s_host.controller, k8s_host.object, k8s_host.namespace)
      end

      def validate_pod_metadata
        @k8s_resolver
          .for_controller(k8s_host.controller)
          .new(controller_object, pod, k8s_object_lookup)
          .validate_pod
      end

      # @return The Conjur resource for the webservice.
      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: k8s_host.account,
          authenticator_name: 'authn-k8s',
          service_id: service_id
        )
      end

      def k8s_object_lookup
        @k8s_object_lookup ||= K8sObjectLookup.new(webservice)
      end

      def host_can_access_service?
        host.role.allowed_to?("authenticate", webservice.resource)
      end

      def host
        @host ||= @resource_repo[k8s_host.conjur_host_id]
      end

      def container
        pod.spec.containers.find { |c| c.name == container_name } ||
          pod.spec.initContainers.find { |c| c.name == container_name }
      end

      def default_container_name
        'authenticator'
      end

      def container_name
        name = 'kubernetes/authentication-container-name'
        annotation = host.annotations.find { |a| a.values[:name] == name }

        return default_container_name unless annotation

        annotation[:value] || default_container_name
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

      def controller_object
        @controller_object ||= k8s_object_lookup.find_object_by_name(
          k8s_host.controller,
          k8s_host.object,
          k8s_host.namespace
        )
      end
    end
  end
end
