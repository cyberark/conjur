require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    ValidateApplicationIdentity ||= CommandClass.new(
      dependencies: {
        resource_class:             ::Resource,
        k8s_resolver:               K8sResolver,
        k8s_object_lookup_class:    K8sObjectLookup,
        application_identity_class: ApplicationIdentity
      },
      inputs:       %i(host_id host_annotations account service_id spiffe_id)
    ) do

      def call
        validate_namespace
        validate_pod_properties
        validate_container
      end

      private

      def validate_namespace
        return if application_identity.namespace == @spiffe_id.namespace
        raise Errors::Authentication::AuthnK8s::NamespaceMismatch.new(
          @spiffe_id.namespace,
          application_identity.namespace
        )
      end

      def validate_pod_properties
        return if application_identity.namespace_scoped?

        validate_pod_metadata
      end

      def validate_container
        unless container
          raise Errors::Authentication::AuthnK8s::ContainerNotFound.new(
            application_identity.container_name,
            @host_id
          )
        end
      end

      def validate_pod_metadata
        application_identity.constraints.each do |constraint|
          resource_type   = constraint[0].to_s
          resource_name   = constraint[1]
          resource_object = k8s_resource_object(
            resource_type,
            resource_name,
            application_identity.namespace
          )

          unless resource_object
            raise Errors::Authentication::AuthnK8s::K8sResourceNotFound.new(
              resource_type, resource_name,
              application_identity.namespace
            )
          end

          @k8s_resolver
            .for_resource(resource_type)
            .new(
              resource_object,
              pod,
              k8s_object_lookup
            )
            .validate_pod
        end
      end

      def k8s_object_lookup
        @k8s_object_lookup ||= @k8s_object_lookup_class.new(webservice)
      end

      # @return The Conjur resource for the webservice.
      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            @account,
          authenticator_name: 'authn-k8s',
          service_id:         @service_id
        )
      end

      def container
        (pod.spec.containers || []).find { |c| c.name == application_identity.container_name } ||
          (pod.spec.initContainers || []).find { |c| c.name == application_identity.container_name }
      end

      def pod
        @pod ||= k8s_object_lookup.pod_by_name(pod_name, pod_namespace)
      end

      def pod_name
        @spiffe_id.name
      end

      def pod_namespace
        @spiffe_id.namespace
      end

      def k8s_resource_object resource_type, resource_name, namespace
        @k8s_resource_object = k8s_object_lookup.find_object_by_name(
          resource_type,
          resource_name,
          namespace
        )
      end

      def application_identity
        @application_identity ||= @application_identity_class.new(
          host_id:          @host_id,
          host_annotations: @host_annotations,
          service_id:       @service_id
        )
      end
    end
  end
end
