require 'forwardable'
require 'command_class'

module Authentication
  module AuthnK8s

    ValidateResourceRestrictions ||= CommandClass.new(
      dependencies: {
        resource_class:              ::Resource,
        k8s_resolver:                K8sResolver,
        k8s_object_lookup_class:     K8sObjectLookup,
        resource_restrictions_class: Authentication::AuthnK8s::ResourceRestrictions,
        logger:                      Rails.logger
      },
      inputs:       %i(host_id host_annotations account service_id spiffe_id)
    ) do

      def call
        extract_resource_restrictions_from_role
        validate_resource_restrictions_matches_request
      end

      private

      def extract_resource_restrictions_from_role
        resource_restrictions
      end

      def resource_restrictions
        @resource_restrictions ||= @resource_restrictions_class.new(
          host_id:          host_id_suffix,
          host_annotations: @host_annotations,
          service_id:       @service_id,
          logger: @logger
        )
      end

      def validate_resource_restrictions_matches_request
        resource_restrictions.resources.each do |resource_from_role|
          resource_type   = underscored_k8s_resource_type(resource_from_role.type)
          resource_value   = resource_from_role.value
          if resource_type == "namespace"
            unless resource_value == @spiffe_id.namespace
              raise Errors::Authentication::AuthnK8s::NamespaceMismatch.new(@spiffe_id.namespace, resource_value)
            end
            next
          end

          resource_from_k8s = k8s_resource_object(
            resource_type,
            resource_value,
            @spiffe_id.namespace
          )

          unless resource_from_k8s
            raise Errors::Authentication::AuthnK8s::K8sResourceNotFound.new(resource_type, resource_value, @spiffe_id.namespace)
          end

          @k8s_resolver
            .for_resource(resource_type)
            .new(
              resource_from_k8s,
              pod,
              k8s_object_lookup
            )
            .validate_pod
        end
        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ValidatedResourceRestrictions.new)
      end

      def k8s_object_lookup
        @k8s_object_lookup ||= @k8s_object_lookup_class.new(webservice)
      end

      def k8s_resource_object resource_type, resource_value, namespace
        @k8s_resource_object = k8s_object_lookup.find_object_by_name(
          resource_type,
          resource_value,
          namespace
        )
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

      # @return The Conjur resource for the webservice
      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account:            @account,
          authenticator_name: 'authn-k8s',
          service_id:         @service_id
        )
      end

      # Return the last three parts of the host id, which consist of the host's
      # resource restrictions
      def host_id_suffix
        @host_id_suffix ||= hostname.split('/').last(3)
      end

      # Return the last part of the host id (which is the actual hostname).
      # The host id is build as "account_name:kind:identifier" (e.g "org:host:some_hostname").
      def hostname
        @hostname ||= @host_id.split(':')[2]
      end

      def underscored_k8s_resource_type resource_type
        resource_type.tr('-', '_')
      end
    end
  end
end
