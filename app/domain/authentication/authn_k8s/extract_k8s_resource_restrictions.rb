require 'command_class'

module Authentication
  module AuthnK8s

    ExtractK8sResourceRestrictions = CommandClass.new(
      dependencies: {
        extract_resource_restrictions: ResourceRestrictions::ExtractResourceRestrictions.new,
        resource_restrictions_class:   ResourceRestrictions::ResourceRestrictions,
        logger:                        Rails.logger
      },
      inputs:   %i(authenticator_name service_id role_name account)
    ) do

      def call
        extract_resource_restrictions
      end

      private

      # Extracts resource restrictions for k8s hosts. It can be defined in the
      # annotations or as part of the host ID itself.
      # If the restrictions are in the annotations, then they will not be
      # extracted from the host ID.
      def extract_resource_restrictions
        restrictions_from_annotations = @extract_resource_restrictions.call(
          authenticator_name: @authenticator_name,
          service_id:         @service_id,
          role_name:          @role_name,
          account:            @account
        )

        # Container name annotation is not a restriction, and needs to be excluded.
        resource_restrictions = restrictions_from_annotations.except(Restrictions::AUTHENTICATION_CONTAINER_NAME)
        return resource_restrictions if resource_restrictions.any?

        @logger.debug(LogMessages::Authentication::AuthnK8s::ExtractingRestrictionsFromHostId.new(@role_name))

        resource_restrictions = resource_restrictions_from_host_id

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ExtractedResourceRestrictions.new(resource_restrictions.names))

        resource_restrictions
      end

      def resource_restrictions_from_host_id
        raise Errors::Authentication::AuthnK8s::InvalidHostId, @host_id if host_id.length != 3

        resource_restrictions_hash = {
          Restrictions::NAMESPACE => host_id[0]
        }

        if host_id_contains_resource_type?
          resource_type = host_id[-2].tr('_', '-')
          resource_name = host_id[-1]
          resource_restrictions_hash[resource_type] = resource_name
        end

        @resource_restrictions_class.new(resource_restrictions_hash: resource_restrictions_hash)
      end

      def host_id_contains_resource_type?
        host_id[-2] != '*' || host_id[-1] != '*'
      end

      def host_id
        @host_id ||= @role_name.delete_prefix('host/').split('/').last(3)
      end
    end
  end
end
