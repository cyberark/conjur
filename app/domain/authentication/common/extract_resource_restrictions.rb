require 'command_class'

module Authentication
  module Common

    ExtractResourceRestrictions = CommandClass.new(
        dependencies: {
            role_class:                  ::Role,
            resource_class:              ::Resource,
            resource_restrictions_class: ResourceRestrictions,
            logger:                      Rails.logger
        },
        inputs:   %i(authenticator_name service_id host_name account)
    ) do

      def call
        annotations = fetch_role_annotations
        resource_restrictions = extract_resource_restrictions_from_annotations(annotations)
        create_resource_restrictions_object(resource_restrictions)
      end

      private

      def fetch_role_annotations
        # Validate role exists, otherwise getting role annotations return empty hash.
        role_id = @role_class.roleid_from_username(@account, @host_name)
        host_resource = @resource_class[role_id]

        raise Errors::Authentication::Security::RoleNotFound, role_id unless host_resource

        host_resource.annotations.each_with_object({}) do |annotation, result|
          result[annotation.values[:name]] = annotation.values[:value]
        end
      end

      def extract_resource_restrictions_from_annotations(annotations)
        resource_restrictions = {}
        annotations.each do |annotation_name, annotation_value|
          prefix_match = annotation_name.match(authenticator_prefix_regex)
          if prefix_match
            # Take the restriction name capture group value from the match
            restriction_name = prefix_match[:restriction_name]
            resource_restrictions[restriction_name] = annotation_value
          end
        end
        resource_restrictions
      end

      def create_resource_restrictions_object(resource_restrictions)
        @resource_restrictions_class.new(
            resource_restrictions: resource_restrictions
        )
      end

      def authenticator_prefix_regex
        # The regex capture group <restriction_name> has the annotation name without the prefix
        @authenticator_prefix_regex ||= Regexp.new("^#{@authenticator_name}/(#{@service_id}/)?(?<restriction_name>[^/]+)$")
      end

    end
  end
end
