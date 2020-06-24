require 'command_class'

module Authentication
  module AuthnAzure

    ValidateAzureAnnotations = CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs:       %i(role_annotations service_id)
    ) do

      def call
        validate_azure_annotations_are_permitted
      end

      private

      # validating that the annotations listed for the Conjur resource align with the permitted Azure constraints
      def validate_azure_annotations_are_permitted
        validate_prefixed_permitted_annotations("authn-azure/")
        validate_prefixed_permitted_annotations("authn-azure/#{@service_id}/")
      end

      # check if annotations with the given prefix is part of the permitted list
      def validate_prefixed_permitted_annotations prefix
        @logger.debug(LogMessages::Authentication::ValidatingAnnotationsWithPrefix.new(prefix))

        prefixed_annotations(prefix).each do |annotation|
          annotation_name = annotation[:name]
          next if prefixed_permitted_constraints(prefix).include?(annotation_name)
          raise Errors::Authentication::AuthnAzure::ConstraintNotSupported.new(
            annotation_name.gsub(prefix, ""),
            permitted_constraints
          )
        end
      end

      def prefixed_annotations prefix
        @role_annotations.select do |a|
          annotation_name = a.values[:name]

          annotation_name.start_with?(prefix) &&
            # verify we take only annotations from the same level
            annotation_name.split('/').length == prefix.split('/').length + 1
        end
      end

      # add prefix to all permitted constraints
      def prefixed_permitted_constraints prefix
        permitted_constraints.map { |k| "#{prefix}#{k}" }
      end

      def permitted_constraints
        @permitted_constraints ||= %w(
          subscription-id resource-group user-assigned-identity system-assigned-identity
        )
      end
    end
  end
end
