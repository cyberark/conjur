require 'command_class'

module Authentication
  module ResourceRestrictions

    ExtractResourceRestrictions = CommandClass.new(
      dependencies: {
        resource_restrictions_class: Authentication::ResourceRestrictions::ResourceRestrictions,
        get_restriction_from_annotation: Authentication::ResourceRestrictions::GetRestrictionFromAnnotation.new,
        fetch_resource_annotations: Authentication::ResourceRestrictions::FetchResourceAnnotations.new,
        role_class: ::Role,
        resource_class: ::Resource,
        logger: Rails.logger,
        ignore_empty_annotations: true
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

        call_fetch_resource_annotations
        extract_resource_restrictions_from_annotations
        create_resource_restrictions_object

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::ExtractedResourceRestrictions.new(resource_restrictions.names))

        resource_restrictions
      end

      private

      def call_fetch_resource_annotations
        resource_annotations
      end

      def resource_annotations
        @resource_annotations ||= @fetch_resource_annotations.call(
          account: @account,
          role_name: @role_name,
          ignore_empty_annotations: @ignore_empty_annotations
        )
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
        restriction_name, is_general_restriction = @get_restriction_from_annotation.call(
          annotation_name: annotation_name,
          authenticator_name: @authenticator_name,
          service_id: @service_id
        )

        return unless restriction_name

        # General restriction should not override existing restriction
        return if is_general_restriction && resource_restrictions_hash.include?(restriction_name)

        @logger.debug(LogMessages::Authentication::ResourceRestrictions::RetrievedAnnotationValue.new(annotation_name))

        resource_restrictions_hash[restriction_name] = annotation_value
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
