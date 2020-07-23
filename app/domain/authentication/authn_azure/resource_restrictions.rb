module Authentication
  module AuthnAzure

    class ApplicationIdentity

      def initialize(role_annotations:, service_id:, logger:)
        @role_annotations = role_annotations
        @service_id       = service_id
        @logger           = logger
      end

      def constraints
        @constraints ||= {
          subscription_id:          constraint_value("subscription-id"),
          resource_group:           constraint_value("resource-group"),
          user_assigned_identity:   constraint_value("user-assigned-identity"),
          system_assigned_identity: constraint_value("system-assigned-identity")
        }.compact
      end

      private

      # check the `service-id` specific constraint first to be more granular
      def constraint_value constraint_name
        annotation_value("authn-azure/#{@service_id}/#{constraint_name}") ||
          annotation_value("authn-azure/#{constraint_name}")
      end

      def annotation_value name
        annotation = @role_annotations.find { |a| a.values[:name] == name }

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          @logger.debug(LogMessages::Authentication::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end
    end
  end
end
