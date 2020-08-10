require 'command_class'

module Authentication
  module AuthnGCP

    # This class is responsible of restrictions extraction that are set on a Conjur host or user as annotations.
    ExtractResourceRestrictions = CommandClass.new(
      dependencies: {
        role_class: ::Role,
        resource_class: ::Resource,
        logger: Rails.logger
      },
      inputs: %i(extraction_prefix account username)
    ) do

      def call
        extract_resource_restrictions
        restrictions_list
      end

      private

      def extract_resource_restrictions
        @logger.debug(LogMessages::Authentication::AuthnGCP::ExtractingRestrictionsFromResource.new(@username, @extraction_prefix))
        prefixed_resource_annotations
        init_restrictions_list
        @logger.debug(LogMessages::Authentication::AuthnGCP::ExtractedResourceRestrictions.new(restrictions_list.length()))
      end

      def restrictions_list
        return @restrictions_list if @restrictions_list

        @restrictions_list = Array.new
      end

      def prefixed_resource_annotations
        @prefixed_resource_annotations ||= resource_annotations.select do |a|
          annotation_name = a.values[:name]
          annotation_name.start_with?(@extraction_prefix)
        end
      end

      def init_restrictions_list
        prefixed_resource_annotations.select do |a|
          annotation_name = a.values[:name]
          resource_value = annotation_value(annotation_name)
          next unless resource_value
          restrictions_list.push(
            ResourceRestriction.new(
              type: annotation_name,
              value: resource_value
            )
          )
        end
      end

      def resource_annotations
        @resource_annotations ||= role.annotations
      end

      def annotation_value name
        annotation = prefixed_resource_annotations.find {|a| a.values[:name] == name}

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          @logger.debug(LogMessages::Authentication::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end

      def role
        return @role if @role

        @role = @resource_class[role_id]
        raise Errors::Authentication::Security::RoleNotFound, role_id unless @role
        @role
      end

      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @username)
      end
    end
  end
end
