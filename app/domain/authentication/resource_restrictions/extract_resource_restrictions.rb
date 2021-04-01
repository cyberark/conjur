require 'command_class'

module Authentication
  module ResourceRestrictions

    ExtractResourceRestrictions = CommandClass.new(
      dependencies: {
        resource_restrictions_class: ResourceRestrictions::ResourceRestrictions,
        role_class: ::Role,
        resource_class: ::Resource,
        logger: Rails.logger
      },
      inputs: %i[authenticator_name service_id role_name account]
    ) do
      def call
        @logger.debug(
          LogMessages::Authentication::ResourceRestrictions::ExtractingRestrictionsFromResource.new(
            @authenticator_name,
            @role_name
          )
        )

        fetch_resource_annotations
        extract_resource_restrictions_from_annotations
        create_resource_restrictions_object

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ExtractedResourceRestrictions.new(resource_restrictions.names))

        resource_restrictions
      end

      private

      def fetch_resource_annotations
        resource_annotations
      end

      def resource_annotations
        @resource_annotations ||=
          resource.annotations.each_with_object({}) do |annotation, result|
            annotation_values = annotation.values
            value = annotation_values[:value]
            next if value.blank?

            result[annotation_values[:name]] = value
          end
      end

      def resource
        # Validate role exists, otherwise getting role annotations return empty hash.
        role_id = @role_class.roleid_from_username(@account, @role_name)
        resource = @resource_class[role_id]

        raise Errors::Authentication::Security::RoleNotFound, role_id unless resource

        resource
      end

      def extract_resource_restrictions_from_annotations
        resource_restrictions_hash
      end

      def resource_restrictions_hash
        @resource_restrictions_hash ||=
          resource_annotations.each_with_object({}) do |(annotation_name, annotation_value), resource_restrictions_hash|
            add_restriction_to_hash(annotation_name, annotation_value, resource_restrictions_hash)
          end
      end

      def add_restriction_to_hash(annotation_name, annotation_value, resource_restrictions_hash)
        restriction_name, is_general_restriction = get_restriction_from_annotation(annotation_name)

        return unless restriction_name

        # General restriction should not override existing restriction
        return if is_general_restriction && resource_restrictions_hash.include?(restriction_name)

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::RetrievedAnnotationValue.new(annotation_name))

        resource_restrictions_hash[restriction_name] = annotation_value
      end

      # Parses the given annotation name and tries to extract a restriction from it.
      # A restriction can have 2 formats:
      # 1. "<Authenticator name>/<Restriction name>"
      # 2. "<Authenticator name>/<Service ID>/<Restriction name>"
      #
      # The first format is a general restriction.
      # This means it is relevant to all services of this authenticator.
      #
      # The second format is specific to the specified service ID.
      # This means all other services will ignore it.
      # Moreover, if both formats are found for the same restriction, the specific one will be used.
      #
      # This function returns the restriction name, if found (nil otherwise) and a
      # boolean indicating if it is a general restriction or not.
      def get_restriction_from_annotation(annotation_name)
        annotation_name.match(authenticator_prefix_regex) do |prefix_match|
          # Take the restriction name from the corresponding capture group in the match
          restriction_name = prefix_match[:restriction_name]
          is_general_restriction = prefix_match[:service_id].blank?
          return restriction_name, is_general_restriction
        end
      end

      def authenticator_prefix_regex
        # The regex capture group <restriction_name> has the annotation name without the prefix
        @authenticator_prefix_regex ||= Regexp.new("^#{@authenticator_name}/(?<service_id>#{@service_id}/)?(?<restriction_name>[^/]+)$")
      end

      def create_resource_restrictions_object
        resource_restrictions
      end

      def resource_restrictions
        @resource_restrictions ||= @resource_restrictions_class.new(
          resource_restrictions_hash: @resource_restrictions_hash
        )
      end
    end
  end
end
