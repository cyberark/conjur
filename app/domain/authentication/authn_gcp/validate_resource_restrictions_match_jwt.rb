module Authentication
  module AuthnGcp

    # This class is responsible for validating resource restrictions values against JWT token.
    # the assumption is that resource restrictions list contains only permitted types which already validated
    # in previous steps
    ValidateResourceRestrictionsMatchJWT = CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs:       %i(resource_restrictions decoded_token annotation_prefix)
    ) do

      def call
        @logger.debug(LogMessages::Authentication::AuthnGcp::ValidatingResourceRestrictionsValues.new)
        validate
        @logger.debug(LogMessages::Authentication::AuthnGcp::ValidatedResourceRestrictionsValues.new)
      end

      private

      def validate
        @resource_restrictions.each do |r|
          resource_type = r.type
          resource_value = r.value
          resource_value_from_token = resource_value_from_token(resource_type_without_prefix(resource_type))
          unless resource_value == resource_value_from_token
            raise Errors::Authentication::Jwt::InvalidResourceRestrictions.new(resource_type)
          end
          @logger.debug(LogMessages::Authentication::ValidatedResourceRestrictionValue.new(resource_type))
        end
      end

      def resource_type_without_prefix(resource_type)
        resource_type.sub(@annotation_prefix, "")
      end

      def resource_value_from_token(resource_type)
        case resource_type
        when PROJECT_ID_RESTRICTION_NAME
          @decoded_token.project_id
        when INSTANCE_NAME_RESTRICTION_NAME
          @decoded_token.instance_name
        when SERVICE_ACCOUNT_ID_RESTRICTION_NAME
          @decoded_token.service_account_id
        when SERVICE_ACCOUNT_EMAIL_RESTRICTION_NAME
          @decoded_token.service_account_email
        end
      end
    end
  end
end
